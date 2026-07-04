output "key_vault_id" {
  description = "Key VaultのResource ID。"
  value       = try(azurerm_key_vault.this[0].id, null)
}

output "key_vault_name" {
  description = "Key Vault名。"
  value       = try(azurerm_key_vault.this[0].name, null)
}

output "key_vault_uri" {
  description = "Key Vault URI。"
  value       = try(azurerm_key_vault.this[0].vault_uri, null)
}

output "key_vault_private_endpoint_id" {
  description = "Key Vault用Private Endpoint ID。"
  value       = try(azurerm_private_endpoint.key_vault[0].id, null)
}
