resource "azurerm_public_ip" "pbip" {
  name                = "psip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
} 
  
locals {
    backend_address_pool_name      = "${var.vnet_name}-beap"
    frontend_port_name             = "${var.vnet_name}-feport"
    frontend_ip_configuration_name = "${var.vnet_name}-feip"
    http_setting_name              = "${var.vnet_name}-be-htst"
    listener_name                  = "${var.vnet_name}-httplstn"
    request_routing_rule_name      = "${var.vnet_name}-rqrt"
    redirect_configuration_name    = "${var.vnet_name}-rdrcfg"
  }

resource "azurerm_application_gateway" "azag" {
  name                     = "hdo3-appgateway"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku {
    name     = "Basic"
    tier     = "Basic"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.app_gateway_subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pbip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}

