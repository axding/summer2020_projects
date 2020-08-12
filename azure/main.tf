provider "azurerm" {
  version = "=2.13.0"

  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "aks-cluster"
  location = "eastus"
}

module "appgw-ingress-k8s-cluster" {
  source                              = "./appgw-ingress-k8s-cluster"
  version                             = "0.1.1"
  resource_group_name                 = azurerm_resource_group.test.name
  location                            = "westus"
  aks_service_principal_app_id        = "<App ID of the service principal>"
  aks_service_principal_client_secret = "<Client secret of the service principal>"
  aks_service_principal_object_id     = "<Object ID of the service principal>"
}

#provider "kubernetes" {
#    load_config_file       = false
#
#    host = azurerm_kubernetes_cluster.test.kube_config[0].host
#
#    client_key             = base64decode(azurerm_kubernetes_cluster.test.kube_config[0].client_key)
#    client_certificate     = base64decode(azurerm_kubernetes_cluster.test.kube_config[0].client_certificate)
#    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.test.kube_config[0].cluster_ca_certificate)
#}

resource "kubernetes_pod" "nginx-pod" {
    metadata {
      name = "nginx"
    }

    spec {
      template {
        metadata {
          labels = {
            App = "nginx"
          }
        }
        spec {
          container {
            image = "nginx:alpine"
            name  = "nginx"

            port {
              container_port = 80
            }

            volume_mount {
                mount_path = "/usr/share/nginx/html"
                name = "volume"
            }
          }
	  volume {
              name = "volume"
              persistent_volume_claim {
                  claim_name = "nginx-azurefile"
              }
          }
        }
      }
    }
}

resource "kubernetes_pod" "flask-pod" {
    metadata {
      name = "flask"
    }

    spec {
      template {
        metadata {
          labels = {
            App = "flask"
          }
        }
        spec {
          container {
            image = "tiangolo/meinheld-gunicorn-flask:python3.8-alpine3.11"
            name  = "flask"

            port {
              container_port = 5000
            }

	    volume_mount {
                mount_path = "/app"
                name = "volume"
            }
          }
	  volume {
              name = "volume"
              persistent_volume_claim {
                  claim_name = "flask-azurefile"
              }
          }
        }
      }
    }
}
