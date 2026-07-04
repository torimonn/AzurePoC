variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "name_prefix" { type = string }
variable "env" { type = string }
variable "enable_udr_to_hub_firewall" { type = bool }
variable "hub_firewall_private_ip" {
  type    = string
  default = null
}
variable "aca_infra_subnet_id" { type = string }
variable "create_admin_vm" { type = bool }
variable "admin_subnet_id" { type = string }
