output "resource_group_name" {
  description = "OCR-Demo Resource Group名。"
  value       = module.resource_group.name
}

output "location" {
  description = "OCR-Demo Resource GroupのAzureリージョン。"
  value       = module.resource_group.location
}

output "vnet_id" {
  description = "OCR-Demo Spoke VNetのResource ID。"
  value       = module.virtual_network.resource_id
}

output "aca_infra_subnet_id" {
  description = "将来のAzure Container Apps Environment用Subnet ID。"
  value       = module.virtual_network.subnets["aca_infra"].resource_id
}

output "private_endpoint_subnet_id" {
  description = "Private Endpoint用Subnet ID。"
  value       = module.virtual_network.subnets["private_endpoint"].resource_id
}

output "admin_subnet_id" {
  description = "管理VM用Subnet ID。create_admin_vmがfalseの場合はnull。"
  value       = try(module.virtual_network.subnets["admin"].resource_id, null)
}

output "log_analytics_workspace_id" {
  description = "Log Analytics WorkspaceのResource ID。"
  value       = module.log_analytics.resource_id
}

output "log_analytics_workspace_name" {
  description = "Log Analytics Workspace名。"
  value       = var.log_analytics_workspace_name
}

output "log_analytics_workspace_customer_id" {
  description = "Log Analytics WorkspaceのCustomer ID。Shared Keyは出力しません。"
  value       = nonsensitive(module.log_analytics.resource.workspace_id)
}

output "ai_account_id" {
  description = "Azure AI ServicesアカウントのResource ID。"
  value       = module.ai_services.resource_id
}

output "ai_account_endpoint" {
  description = "Azure AI ServicesアカウントのEndpoint。"
  value       = module.ai_services.endpoint
}

output "ai_project_id" {
  description = "Azure AI Foundry ProjectのResource ID。"
  value       = azurerm_cognitive_account_project.this.id
}

output "ai_private_dns_zone_ids" {
  description = "Azure AI系Private DNS Zone IDのmap。"
  value = {
    cognitive_services = module.private_dns_zones["cognitive_services"].resource_id
    openai             = module.private_dns_zones["openai"].resource_id
    ai_services        = module.private_dns_zones["ai_services"].resource_id
  }
}

output "ai_private_endpoint_id" {
  description = "Azure AI Services用Private Endpoint ID。"
  value       = module.ai_services.private_endpoints["account"].id
}

output "storage_account_id" {
  description = "アプリ用Storage AccountのResource ID。"
  value       = try(module.storage_account[0].resource_id, null)
}

output "storage_account_name" {
  description = "アプリ用Storage Account名。"
  value       = try(module.storage_account[0].name, null)
}

output "storage_blob_endpoint" {
  description = "Storage AccountのBlob Endpoint。"
  value       = var.create_storage_account ? "https://${module.storage_account[0].name}.blob.core.windows.net/" : null
}

output "blob_private_dns_zone_id" {
  description = "Blob用Private DNS Zone ID。"
  value       = module.private_dns_zones["blob"].resource_id
}

output "blob_private_endpoint_id" {
  description = "Blob用Private Endpoint ID。"
  value       = try(module.storage_account[0].private_endpoints["blob"].id, null)
}

output "state_storage_private_endpoint_id" {
  description = "Terraform state用Storage AccountのBlob Private Endpoint ID。無効時はnull。"
  value       = try(module.state_storage_private_endpoint[0].resource_id, null)
}

output "key_vault_id" {
  description = "Key VaultのResource ID。"
  value       = try(module.key_vault[0].resource_id, null)
}

output "key_vault_name" {
  description = "Key Vault名。"
  value       = try(module.key_vault[0].name, null)
}

output "key_vault_uri" {
  description = "Key Vault URI。"
  value       = try(module.key_vault[0].uri, null)
}

output "key_vault_private_dns_zone_id" {
  description = "Key Vault用Private DNS Zone ID。"
  value       = module.private_dns_zones["key_vault"].resource_id
}

output "key_vault_private_endpoint_id" {
  description = "Key Vault用Private Endpoint ID。"
  value       = try(module.key_vault[0].private_endpoints["vault"].id, null)
}

output "admin_vm_private_ip" {
  description = "管理VMのPrivate IP。create_admin_vmがfalseの場合はnull。"
  value       = try(module.admin_vm[0].virtual_machine_azurerm.private_ip_address, null)
}

output "admin_vm_entra_id_login_enabled" {
  description = "管理VMでMicrosoft Entra ID SSH認証拡張を有効化しているかどうか。"
  value       = var.create_admin_vm && var.enable_admin_vm_entra_id_login
}

output "udr_to_hub_firewall_enabled" {
  description = "Hub Firewall向けUDRを有効化しているかどうか。"
  value       = var.enable_udr_to_hub_firewall
}

output "hub_firewall_private_ip" {
  description = "UDRのNext Hopに使うHub Azure FirewallのPrivate IP。"
  value       = var.hub_firewall_private_ip
}

output "route_table_id" {
  description = "Hub Firewall向けRoute Table ID。UDR無効時はnull。"
  value       = try(module.route_table[0].resource_id, null)
}
