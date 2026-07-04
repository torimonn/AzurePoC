output "resource_group_name" {
  description = "作成したResource Group名。"
  value       = azurerm_resource_group.this.name
}

output "location" {
  description = "Resource GroupのAzureリージョン。"
  value       = azurerm_resource_group.this.location
}

output "vnet_id" {
  description = "OCR Demo Spoke VNetのResource ID。"
  value       = module.network.vnet_id
}

output "aca_infra_subnet_id" {
  description = "将来のAzure Container Apps Environment用Subnet ID。"
  value       = module.network.aca_infra_subnet_id
}

output "private_endpoint_subnet_id" {
  description = "Private Endpoint用Subnet ID。"
  value       = module.network.private_endpoint_subnet_id
}

output "admin_subnet_id" {
  description = "管理VM用Subnet ID。create_admin_vmがfalseの場合はnull。"
  value       = module.network.admin_subnet_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics WorkspaceのResource ID。"
  value       = module.log_analytics.log_analytics_workspace_id
}

output "log_analytics_workspace_customer_id" {
  description = "Log Analytics WorkspaceのCustomer ID。"
  value       = module.log_analytics.log_analytics_workspace_customer_id
}

output "log_analytics_workspace_primary_shared_key" {
  description = "Log Analytics WorkspaceのPrimary Shared Key。"
  value       = module.log_analytics.log_analytics_workspace_primary_shared_key
  sensitive   = true
}

output "ai_account_id" {
  description = "Azure AI ServicesアカウントのResource ID。"
  value       = module.ai_foundry.ai_account_id
}

output "ai_account_endpoint" {
  description = "Azure AI ServicesアカウントのEndpoint。"
  value       = module.ai_foundry.ai_account_endpoint
}

output "ai_project_id" {
  description = "Azure AI Foundry ProjectのResource ID。"
  value       = module.ai_foundry.ai_project_id
}

output "ai_private_dns_zone_ids" {
  description = "Azure AI系Private DNS Zone IDのmap。"
  value       = module.private_dns.ai_private_dns_zone_ids
}

output "admin_vm_private_ip" {
  description = "管理VMのPrivate IP。create_admin_vmがfalseの場合はnull。"
  value       = module.admin_vm.admin_vm_private_ip
}

output "udr_to_hub_firewall_enabled" {
  description = "Hub Firewall向けUDRを有効化しているかどうか。"
  value       = module.udr.udr_to_hub_firewall_enabled
}

output "hub_firewall_private_ip" {
  description = "UDRのNext Hopに使うHub Azure FirewallのPrivate IP。"
  value       = var.hub_firewall_private_ip
}

output "route_table_id" {
  description = "Hub Firewall向けRoute Table ID。UDR無効時はnull。"
  value       = module.udr.route_table_id
}

output "storage_account_id" {
  description = "Blob Storage用Storage AccountのResource ID。"
  value       = module.storage.storage_account_id
}

output "storage_account_name" {
  description = "Blob Storage用Storage Account名。"
  value       = module.storage.storage_account_name
}

output "storage_blob_endpoint" {
  description = "Storage AccountのBlob Endpoint。"
  value       = module.storage.storage_blob_endpoint
}

output "blob_container_name" {
  description = "将来作成するBlob Container名。"
  value       = var.blob_container_name
}

output "blob_private_dns_zone_id" {
  description = "Blob用Private DNS Zone ID。"
  value       = module.private_dns.blob_private_dns_zone_id
}

output "blob_private_endpoint_id" {
  description = "Blob用Private Endpoint ID。"
  value       = module.storage.blob_private_endpoint_id
}

output "key_vault_id" {
  description = "Key VaultのResource ID。"
  value       = module.key_vault.key_vault_id
}

output "key_vault_name" {
  description = "Key Vault名。"
  value       = module.key_vault.key_vault_name
}

output "key_vault_uri" {
  description = "Key Vault URI。"
  value       = module.key_vault.key_vault_uri
}

output "key_vault_private_dns_zone_id" {
  description = "Key Vault用Private DNS Zone ID。"
  value       = module.private_dns.key_vault_private_dns_zone_id
}

output "key_vault_private_endpoint_id" {
  description = "Key Vault用Private Endpoint ID。"
  value       = module.key_vault.key_vault_private_endpoint_id
}
