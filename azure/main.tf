provider "azurerm" {
  version = "=2.13.0"

  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "aks-cluster"
  location = "eastus"
}

#data "azurerm_user_assigned_identity" "default" {
#  name                = "${azurerm_kubernetes_cluster.cluster.name}-agentpool"
#  resource_group_name = azurerm_kubernetes_cluster.cluster.node_resource_group
#}

#resource "azurerm_role_assignment" "aks_sp_container_registry" {
#  scope                            = azurerm_container_registry.default.id
#  role_definition_name             = "AcrPull"
#  principal_id                     = data.azurerm_user_assigned_identity.default.principal_id
#  skip_service_principal_aad_check = true
#}

resource "azurerm_kubernetes_cluster" "cluster" {
  name       = "aks"
  location   = azurerm_resource_group.rg.location
  dns_prefix = "aks"

  resource_group_name = azurerm_resource_group.rg.name
  kubernetes_version  = "1.18.2"

  default_node_pool {
    name       = "aks"
    node_count = "1"
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }
}

provider "kubernetes" {
    load_config_file       = false

    host = azurerm_kubernetes_cluster.cluster.kube_config[0].host

    client_key             = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].client_key)
    client_certificate     = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].client_certificate)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate)
}

resource "kubernetes_storage_class" "nginx-storage" {
  metadata {
    name = "nginx-azurefile"
  }
  storage_provisioner = "kubernetes.io/azure-file"
  parameters = {
    skuName = "Standard_LRS"
  }
  mount_options = ["file_mode=0755", "dir_mode=0755", "mfsymlinks", "uid=0", "gid=0", "cache=strict"]
}

resource "kubernetes_persistent_volume_claim" "nginx-pvc" {
  metadata {
    name = "nginx-azurefile"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    storage_class_name = "nginx-azurefile"
  }
}

resource "kubernetes_deployment" "nginx-deployment" {
    metadata {
      name = "nginx"
    }

    spec {
      replicas = 1
      selector {
        match_labels = {
          App = "nginx"
        }
      }
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

resource "kubernetes_storage_class" "flask-storage" {
  metadata {
    name = "flask-azurefile"
  }
  storage_provisioner = "kubernetes.io/azure-file"
  parameters = {
    skuName = "Standard_LRS"
  }
  mount_options = ["file_mode=0755", "dir_mode=0755", "mfsymlinks", "uid=0", "gid=0", "cache=strict"]
}

resource "kubernetes_persistent_volume_claim" "flask-pvc" {
  metadata {
    name = "flask-azurefile"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
    storage_class_name = "flask-azurefile"
  }
}

resource "kubernetes_deployment" "flask-deployment" {
    metadata {
      name = "flask"
    }

    spec {
      replicas = 1
      selector {
        match_labels = {
          App = "flask"
        }
      }
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
              container_port = 80
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

resource "kubernetes_service" "nginx-service" {
  metadata {
    name = "nginx"
  }
  spec {
    selector = {
      App = "nginx"
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service" "flask-service" {
  metadata {
    name = "flask"
  }
  spec {
    selector = {
      App = "flask"
    }
    port {
      port        = 5000
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_ingress" "example_ingress" {
  metadata {
    name = "example-ingress"
  }

  spec {
    rule {
      http {
        path {
          backend {
            service_name = "nginx"
            service_port = 80
          }

          path = "/"
        }

        path {
          backend {
            service_name = "flask"
            service_port = 5000
          }

          path = "/app1"
        }
      }
    }
  }
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.cluster.kube_config_raw
}

output "lb_ip" {
  value = kubernetes_service.flask-service.load_balancer_ingress[0].ip
}

output "nginx_ip" {
  value = kubernetes_service.nginx-service.load_balancer_ingress[0].ip
}
