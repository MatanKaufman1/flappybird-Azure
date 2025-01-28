resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/22"]  
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "aks-private-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/25"]  
}

#resource "azurerm_subnet" "agfc_subnet" {
#  name                 = "agfc-subnet"
#  resource_group_name  = var.resource_group_name
#  virtual_network_name = azurerm_virtual_network.vnet.name
#  address_prefixes     = ["10.0.1.0/24"]  
#}
