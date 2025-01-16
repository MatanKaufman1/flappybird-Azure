module "keyvault" {
  source              = "./keyvault"
  resource_group_name = var.resource_group_name
  location            = var.location
  key_vault_name      = var.key_vault_name
}

module "acr" {
  source              = "./acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  acr_name            = var.acr_name
}

module "network" {
  source              = "./network"
  resource_group_name = var.resource_group_name
  location            = var.location
}

module "aks" {
  source              = "./aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  aks_cluster_name    = var.aks_cluster_name
  node_count          = var.node_count
  vnet_subnet_id      = module.network.private_subnet_id
}

module "sql_server" {
  source              = "./sql_server"
  resource_group_name = var.resource_group_name
  location            = var.location
  key_vault_name      = module.keyvault.key_vault_name
  sql_server_name     = var.sql_server_name
  sql_database_name   = var.sql_database_name
}

module "application_gateway" {
  source                = "./application_gateway"
  resource_group_name   = var.resource_group_name
  location              = var.location
  app_gateway_subnet_id = module.network.app_gateway_subnet_id
  vnet_name             = module.network.vnet_name
}

