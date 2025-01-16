resource "azurerm_virtual_network" "vnet" {
  name                = "my-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/24"]  # Smaller address space
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "aks-private-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/25"]  # Private subnet with smaller IP range
}

resource "azurerm_subnet" "app_gateway_subnet" {
  name                 = "app-gateway-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.128/25"]  # Subnet for Application Gateway
}


# Network Security Group for Application Gateway
resource "azurerm_network_security_group" "app_gateway_nsg" {
  name                = "app-gateway-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# NSG Rule for HTTP (Port 80)
resource "azurerm_network_security_rule" "http_inbound" {
  name                        = "allow-http-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app_gateway_nsg.name
}

# Associate NSG with Application Gateway Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.app_gateway_subnet.id
  network_security_group_id = azurerm_network_security_group.app_gateway_nsg.id
}
