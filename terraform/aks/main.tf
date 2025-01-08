data "azurerm_resource_group" "aks_rg" {
  name     = var.resource_group_name
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location
  sku                 = "Basic"
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  dns_prefix          = "${var.aks_cluster_name}-dns"

  default_node_pool {
    name       = "nodepool"
    node_count = var.node_count
    vm_size    = "Standard_A2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "Development"
  }
}

resource "azurerm_role_assignment" "arm_pe" {
  principal_id                     = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
data "azurerm_key_vault" "flappykey" {
  name                = "matankeyvault"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
}

# Fetch the SQL admin login from Key Vault
data "azurerm_key_vault_secret" "sql_admin_login" {
  name         = "AZURE-SQL-USERNAME"
  key_vault_id = data.azurerm_key_vault.flappykey.id
}

# Fetch the SQL admin password from Key Vault
data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "MSQL-PASSWORD" # Secret name in Key Vault
  key_vault_id = data.azurerm_key_vault.flappykey.id
}

resource "azurerm_mssql_server" "sql-server" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = data.azurerm_key_vault_secret.sql_admin_login.value
  administrator_login_password = data.azurerm_key_vault_secret.sql_admin_password.value
}

#data "azurerm_mssql_database" "flappy-db" {
#  name      = "flappy-db"
#  server_id = azurerm_mssql_server.sql-server.id
#}

resource "azurerm_mssql_database" "sql-server" {
  name           = "flappy-db"
  server_id      = azurerm_mssql_server.sql-server.id
  max_size_gb    = 2
  sku_name       = "S0"
}