# # Locals block for hardcoded names.
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.test.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.test.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.test.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.test.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.test.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.test.name}-rqrt"

  #networkContributorRole         = "[concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Authorization/roleDefinitions/', '4d97b98b-1d4f-4787-a291-c67834d212e7')]"

  app_gateway_subnet_name = "appgwsubnet"
}

#Resources
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# User Assigned Idntities
resource "azurerm_user_assigned_identity" "testIdentity" {
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  name = "identity1"

  tags = var.tags
}

#Virtual Networks
resource "azurerm_virtual_network" "test" {
  name                = var.virtual_network_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = [var.virtual_network_address_prefix]

  subnet {
    name           = var.aks_subnet_name
    address_prefix = var.aks_subnet_address_prefix # Kubernetes Subnet Address prefix
  }

  subnet {
    name           = "appgwsubnet" # Has to be hardcoded to this name.
    address_prefix = var.app_gateway_subnet_address_prefix
  }

  tags = var.tags
}

data "azurerm_subnet" "kubesubnet" {
  name                 = var.aks_subnet_name
  virtual_network_name = azurerm_virtual_network.test.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "appgwsubnet" {
  name                 = "appgwsubnet" #Hardcoded to this name.
  virtual_network_name = azurerm_virtual_network.test.name
  resource_group_name  = data.azurerm_resource_group.rg.name
}

# Public Ip
resource "azurerm_public_ip" "test" {
  name                         = "publicIp1"
  location                     = data.azurerm_resource_group.rg.location
  resource_group_name          = data.azurerm_resource_group.rg.name
  allocation_method            = "Static"
  sku                          = "Standard"

  tags = var.tags
}

resource "azurerm_application_gateway" "network" {
  name                = var.app_gateway_name
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  sku {
    name     = var.app_gateway_sku
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = data.azurerm_subnet.appgwsubnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  # frontend_port {
  #  name = "httpsPort"
  #  port = 443
  # }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.test.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  ## a pool for each associated backend_http_settings as it will pick up its port 
  backend_address_pool {
    name = "beap-path-app1"
  }

  backend_address_pool {
    name = "beap-path-jenkins"
  }

  probe {
    name                = "probe-default"
    protocol            = "http"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    path                = "/"
    host                = "127.0.0.1"
  }

  probe {
    name                = "probe-jenkins"
    protocol            = "http"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    # for a /jenkins prefix to serve other static resource URLs
    path                = "/jenkins/login"
    host                = "127.0.0.1"
  }

  # ref: https://docs.microsoft.com/en-us/azure/application-gateway/configuration-overview#http-settings
  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    probe_name            = "probe-default"
    protocol              = "Http"
    request_timeout       = 1
  }

  backend_http_settings {
    name                  = "behs-path-app1"
    cookie_based_affinity = "Disabled"
    # override path to the app1
    path                  = "/"
    port                  = 5000
    probe_name            = "probe-default"
    # jcdemo/flaskapp is a pure flask app on port 5000, with both / and /json routes configured
    protocol              = "Http"
    request_timeout       = 1
  }

  backend_http_settings {
    name                  = "behs-path-jenkins"
    cookie_based_affinity = "Disabled"
    port                  = 8080
    probe_name            = "probe-jenkins"
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rqrl-path-app1"
    rule_type                  = "PathBasedRouting"
    http_listener_name         = local.listener_name
    url_path_map_name          = "urlmap-all"
  }

  url_path_map {
    name                               = "urlmap-all"
    default_backend_address_pool_name  = local.backend_address_pool_name
    default_backend_http_settings_name = local.http_setting_name

    path_rule {
      name                       = "pathrule-app1"
      paths                      = ["/app1/", "/app1/*"]
      backend_address_pool_name  = "beap-path-app1"
      backend_http_settings_name = "behs-path-app1"
    }
  
    path_rule {
      name                       = "pathrule-jenkins"
      paths                      = ["/jenkins/", "/jenkins/*"]
      backend_address_pool_name  = "beap-path-jenkins"
      backend_http_settings_name = "behs-path-jenkins"
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_virtual_network.test,
    azurerm_public_ip.test,
  ]
}

resource "azurerm_role_assignment" "ra1" {
  scope                = data.azurerm_subnet.kubesubnet.id
  role_definition_name = "Network Contributor"
  principal_id         = var.aks_service_principal_object_id

  depends_on = [azurerm_virtual_network.test]
}

resource "azurerm_role_assignment" "ra2" {
  scope                = azurerm_user_assigned_identity.testIdentity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.aks_service_principal_object_id
  depends_on           = [azurerm_user_assigned_identity.testIdentity]
}

resource "azurerm_role_assignment" "ra3" {
  scope                = azurerm_application_gateway.network.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.testIdentity.principal_id
  depends_on = [
    azurerm_user_assigned_identity.testIdentity,
    azurerm_application_gateway.network,
  ]
}

resource "azurerm_role_assignment" "ra4" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.testIdentity.principal_id
  depends_on = [
    azurerm_user_assigned_identity.testIdentity,
    azurerm_application_gateway.network,
  ]
}

resource "azurerm_kubernetes_cluster" "test" {
  name       = var.aks_name
  location   = data.azurerm_resource_group.rg.location
  dns_prefix = var.aks_dns_prefix

  resource_group_name = data.azurerm_resource_group.rg.name

  linux_profile {
    admin_username = var.vm_user_name

    ssh_key {
      key_data = file(var.public_ssh_key_path)
    }
  }

  addon_profile {
    http_application_routing {
      enabled = false
    }
    kube_dashboard {
      enabled = false
    }
  }

  default_node_pool {
    name            = "agentpool"
    node_count      = var.aks_agent_count
    vm_size         = var.aks_agent_vm_size
    os_disk_size_gb = var.aks_agent_os_disk_size
    vnet_subnet_id  = data.azurerm_subnet.kubesubnet.id
    # dns_prefix     MISSING
  }

  service_principal {
    client_id     = var.aks_service_principal_app_id
    client_secret = var.aks_service_principal_client_secret
  }

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = var.aks_dns_service_ip
    docker_bridge_cidr = var.aks_docker_bridge_cidr
    service_cidr       = var.aks_service_cidr
  }

  depends_on = [
    azurerm_virtual_network.test,
    azurerm_application_gateway.network,
  ]
  tags = var.tags
}

## ref: https://github.com/gustavozimm/terraform-aks-app-gateway-ingress/blob/master/main.tf
# Initialize kubernetes provider to access new deployed cluster
provider "kubernetes" {
  version           = ">=1.9"
  load_config_file  = false
  host              = azurerm_kubernetes_cluster.test.kube_config[0].host
  username          = azurerm_kubernetes_cluster.test.kube_config[0].username
  password          = azurerm_kubernetes_cluster.test.kube_config[0].password
  client_certificate = base64decode(azurerm_kubernetes_cluster.test.kube_config[0].client_certificate)
  client_key = base64decode(azurerm_kubernetes_cluster.test.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.test.kube_config[0].cluster_ca_certificate)
}

# .kube/config
provider "null" {
  version = ">=2.1"
}

resource "null_resource" "main" {
  provisioner "local-exec" {
    command = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${var.aks_name} --overwrite-existing"
    # command = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${var.aks_name} --overwrite-existing && kubectl apply -f deployment.yaml" # && kubectl create namespace wavy-whatsapp && kubectl create secret tls wavy-global --key wildcard_wavy_global.key --cert wildcard_wavy_global.crt -n wavy-whatsapp"
  }
  depends_on = [
    kubernetes_storage_class.pvc,
    kubernetes_cluster_role.pvc,
    kubernetes_cluster_role_binding.pvc,
    kubernetes_persistent_volume_claim.pvc
  ]
}

