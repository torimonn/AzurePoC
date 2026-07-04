output "route_table_id" {
  description = "Hub Firewall向けRoute Table ID。"
  value       = try(azurerm_route_table.this[0].id, null)
}

output "udr_to_hub_firewall_enabled" {
  description = "Hub Firewall向けUDRが有効かどうか。"
  value       = var.enable_udr_to_hub_firewall
}
