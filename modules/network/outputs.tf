output "vnet_id" {
  description = "VNetのResource ID。"
  value       = azurerm_virtual_network.this.id
}

output "aca_infra_subnet_id" {
  description = "ACA用Subnet ID。"
  value       = azurerm_subnet.aca_infra.id
}

output "private_endpoint_subnet_id" {
  description = "Private Endpoint用Subnet ID。"
  value       = azurerm_subnet.private_endpoint.id
}

output "admin_subnet_id" {
  description = "管理VM用Subnet ID。"
  value       = try(azurerm_subnet.admin[0].id, null)
}
