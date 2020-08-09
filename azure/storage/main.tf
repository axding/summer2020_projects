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
