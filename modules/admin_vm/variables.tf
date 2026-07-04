variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "create_admin_vm" { type = bool }
variable "snet_admin_name" { type = string }
variable "admin_subnet_id" { type = string }
variable "admin_vm_name" { type = string }
variable "admin_vm_size" { type = string }
variable "admin_username" { type = string }
variable "admin_private_ip_address" { type = string }
variable "admin_ssh_public_key" {
  type      = string
  sensitive = true
}
variable "hub_azure_bastion_subnet_prefix" {
  type    = string
  default = null
}
