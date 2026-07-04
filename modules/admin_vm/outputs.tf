output "admin_vm_id" {
  description = "管理VMのResource ID。"
  value       = try(azurerm_linux_virtual_machine.this[0].id, null)
}

output "admin_vm_private_ip" {
  description = "管理VMのPrivate IP。"
  value       = try(azurerm_network_interface.this[0].private_ip_address, null)
}

output "admin_nic_id" {
  description = "管理VM NICのResource ID。"
  value       = try(azurerm_network_interface.this[0].id, null)
}

output "admin_nsg_id" {
  description = "管理VM用NSGのResource ID。"
  value       = try(azurerm_network_security_group.this[0].id, null)
}
