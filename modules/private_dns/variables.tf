variable "resource_group_name" {
  type        = string
  description = "Resource Group名。"
}

variable "tags" {
  type        = map(string)
  description = "共通タグ。"
  default     = {}
}

variable "name_prefix" {
  type        = string
  description = "リソース名プレフィックス。"
}

variable "env" {
  type        = string
  description = "環境名。"
}

variable "vnet_id" {
  type        = string
  description = "Private DNS ZoneをリンクするVNet ID。"
}

variable "create_storage_account" {
  type        = bool
  description = "Blob用Private DNS Zoneを作成するかどうか。"
}

variable "create_key_vault" {
  type        = bool
  description = "Key Vault用Private DNS Zoneを作成するかどうか。"
}
