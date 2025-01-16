variable "resource_group_name" {
  type        = string
  description = "The name of the resource group"
}

variable "location" {
  type        = string
  description = "The Azure region to deploy the resources"
}

variable "app_gateway_subnet_id" {
  type        = string
  description = "The subnet ID for the Application Gateway"
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

