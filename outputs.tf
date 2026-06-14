output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "aca_infra_subnet_id" {
  value = azurerm_subnet.aca_infra.id
}

output "private_endpoint_subnet_id" {
  value = azurerm_subnet.private_endpoint.id
}

output "admin_subnet_id" {
  value = try(azurerm_subnet.admin[0].id, null)
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_customer_id" {
  value = azurerm_log_analytics_workspace.this.workspace_id
}

output "log_analytics_workspace_primary_shared_key" {
  value     = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive = true
}

output "ai_account_id" {
  value = azurerm_cognitive_account.ai.id
}

output "ai_account_endpoint" {
  value = azurerm_cognitive_account.ai.endpoint
}

output "ai_project_id" {
  value = azurerm_cognitive_account_project.default.id
}

output "ai_private_dns_zone_ids" {
  value = { for name, zone in azurerm_private_dns_zone.ai : name => zone.id }
}

output "admin_vm_private_ip" {
  value = try(azurerm_network_interface.admin[0].private_ip_address, null)
}

output "storage_account_id" {
  value = try(azurerm_storage_account.blob[0].id, null)
}

output "storage_account_name" {
  value = try(azurerm_storage_account.blob[0].name, null)
}

output "storage_blob_endpoint" {
  value = try(azurerm_storage_account.blob[0].primary_blob_endpoint, null)
}

output "blob_container_name" {
  value = var.blob_container_name
}

output "blob_private_dns_zone_id" {
  value = try(azurerm_private_dns_zone.blob[0].id, null)
}

output "blob_private_endpoint_id" {
  value = try(azurerm_private_endpoint.blob[0].id, null)
}

output "key_vault_id" {
  value = try(azurerm_key_vault.this[0].id, null)
}

output "key_vault_name" {
  value = try(azurerm_key_vault.this[0].name, null)
}

output "key_vault_uri" {
  value = try(azurerm_key_vault.this[0].vault_uri, null)
}

output "key_vault_private_dns_zone_id" {
  value = try(azurerm_private_dns_zone.key_vault[0].id, null)
}

output "key_vault_private_endpoint_id" {
  value = try(azurerm_private_endpoint.key_vault[0].id, null)
}
