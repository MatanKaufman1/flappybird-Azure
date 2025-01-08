#output "kube_config" {
#  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
#  sensitive = true
#}

#output "resource_group_name" {
#  value = azurerm_resource_group.aks_rg.name
#}

#output "aks_cluster_name" {
#  value = azurerm_kubernetes_cluster.aks_cluster.name
#}

#output "database_id" {
#  value = data.azurerm_mssql_database.example.id
#}
output "resource_group_name" {
  value = azurerm_resource_group.aks_rg.name
}