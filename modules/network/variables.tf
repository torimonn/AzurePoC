variable "resource_group_name" {
  type        = string
  description = "Resource Group名。"
}

variable "location" {
  type        = string
  description = "Azureリージョン。"
}

variable "tags" {
  type        = map(string)
  description = "共通タグ。"
  default     = {}
}

variable "vnet_name" {
  type        = string
  description = "VNet名。"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNetのアドレス空間。"
}

variable "dns_servers" {
  type        = list(string)
  description = "カスタムDNSサーバー。"
  default     = []
}

variable "snet_aca_infra_name" {
  type        = string
  description = "ACA用Subnet名。"
}

variable "snet_aca_infra_prefixes" {
  type        = list(string)
  description = "ACA用Subnet CIDR。"
}

variable "snet_private_endpoint_name" {
  type        = string
  description = "Private Endpoint用Subnet名。"
}

variable "snet_private_endpoint_prefixes" {
  type        = list(string)
  description = "Private Endpoint用Subnet CIDR。"
}

variable "create_admin_vm" {
  type        = bool
  description = "管理VM用Subnetを作成するかどうか。"
}

variable "snet_admin_name" {
  type        = string
  description = "管理VM用Subnet名。"
}

variable "snet_admin_prefixes" {
  type        = list(string)
  description = "管理VM用Subnet CIDR。"
}
