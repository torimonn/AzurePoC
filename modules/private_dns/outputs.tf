output "ai_private_dns_zone_ids" {
  description = "AI系Private DNS Zone IDのmap。"
  value       = { for name, zone in azurerm_private_dns_zone.ai : name => zone.id }
}

output "blob_private_dns_zone_id" {
  description = "Blob用Private DNS Zone ID。"
  value       = try(azurerm_private_dns_zone.blob[0].id, null)
}

output "key_vault_private_dns_zone_id" {
  description = "Key Vault用Private DNS Zone ID。"
  value       = try(azurerm_private_dns_zone.key_vault[0].id, null)
}
