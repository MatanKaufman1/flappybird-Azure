resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.aks_cluster_name}-dns"

  network_profile {
    service_cidr   = "10.1.0.0/24"
    dns_service_ip = "10.1.0.10"
    network_plugin = "azure"
  }

  default_node_pool {
    name               = "default"
    node_count         = var.node_count
    vm_size            = "Standard_A2_v2"
    vnet_subnet_id     = var.vnet_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }
}

