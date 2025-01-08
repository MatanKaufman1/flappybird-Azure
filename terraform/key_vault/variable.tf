variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
  default     = "FlappyBird"
}

variable "location" {
  description = "Azure region for the resources."
  type        = string
  default     = "germanywestcentral"
}

variable "azure_key_vault_name" {
  description = "this is azure_key_vault"
  type        = string
  default     = "matankeyvault"

}

