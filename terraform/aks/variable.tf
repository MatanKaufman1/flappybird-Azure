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

variable "acr_name" {
  description = "Azure Container registry name."
  type        = string
  default     = "hdo3acrflappy"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = "flappybird-aks"
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 1
}

variable "client_id" {
  description = "Service principal client ID for AKS."
  type        = string
}

variable "client_secret" {
  description = "Service principal client secret for AKS."
  type        = string
}

variable "sql_server_name" {
  description = "this is sql-server name"
  type        = string
  default     = "flappy-sql-srv"
}

variable "sql_database_name" {
  description = "this is the database name"
  type        = string
  default     = "flappy-db"
}

