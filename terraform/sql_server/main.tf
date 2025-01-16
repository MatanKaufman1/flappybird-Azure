data "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

# Fetch the SQL admin login from Key Vault
data "azurerm_key_vault_secret" "sql_admin_login" {
  name         = "SQL-Admin-Login"
  key_vault_id = data.azurerm_key_vault.kv.id
}

# Fetch the SQL admin password from Key Vault
data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "SQL-Admin-Password"
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = data.azurerm_key_vault_secret.sql_admin_login.value
  administrator_login_password = data.azurerm_key_vault_secret.sql_admin_password.value
}

resource "azurerm_mssql_database" "sql_database" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.sql_server.id
  max_size_gb    = 2
  sku_name       = "S0"
}

