output "storage_account_id" {
  description = "Storage AccountのResource ID。"
  value       = try(azurerm_storage_account.this[0].id, null)
}

output "storage_account_name" {
  description = "Storage Account名。"
  value       = try(azurerm_storage_account.this[0].name, null)
}

output "storage_blob_endpoint" {
  description = "Storage AccountのBlob Endpoint。"
  value       = try(azurerm_storage_account.this[0].primary_blob_endpoint, null)
}

output "blob_private_endpoint_id" {
  description = "Blob用Private Endpoint ID。"
  value       = try(azurerm_private_endpoint.blob[0].id, null)
}
