variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "create_key_vault" { type = bool }
variable "key_vault_name" { type = string }
variable "key_vault_sku_name" { type = string }
variable "enable_key_vault_private_only_access" { type = bool }
variable "key_vault_public_network_access_enabled" { type = bool }
variable "key_vault_network_default_action" { type = string }
variable "key_vault_network_bypass" { type = string }
variable "key_vault_soft_delete_retention_days" { type = number }
variable "key_vault_purge_protection_enabled" { type = bool }
variable "private_endpoint_subnet_id" { type = string }
variable "key_vault_private_dns_zone_id" { type = string }
