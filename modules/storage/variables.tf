variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "create_storage_account" { type = bool }
variable "storage_account_name" { type = string }
variable "storage_account_tier" { type = string }
variable "storage_account_replication_type" { type = string }
variable "storage_account_access_tier" { type = string }
variable "enable_storage_private_only_access" { type = bool }
variable "storage_public_network_access_enabled" { type = bool }
variable "storage_network_default_action" { type = string }
variable "storage_network_bypass" { type = list(string) }
variable "storage_shared_access_key_enabled" { type = bool }
variable "create_blob_container" { type = bool }
variable "blob_container_name" { type = string }
variable "private_endpoint_subnet_id" { type = string }
variable "blob_private_dns_zone_id" { type = string }
