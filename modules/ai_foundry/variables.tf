variable "resource_group_name" {
  type        = string
  description = "Resource Group名。"
}

variable "location" {
  type        = string
  description = "Azure AI Servicesのリージョン。"
}

variable "tags" {
  type        = map(string)
  description = "共通タグ。"
  default     = {}
}

variable "ai_account_name" {
  type        = string
  description = "Azure AI Servicesアカウント名。"
}

variable "ai_sku_name" {
  type        = string
  description = "Azure AI Services SKU。"
}

variable "ai_project_name" {
  type        = string
  description = "Azure AI Foundry Project名。"
}

variable "enable_ai_private_only_access" {
  type        = bool
  description = "AI ServicesをPrivate Onlyにするかどうか。"
}

variable "ai_public_network_access_enabled" {
  type        = bool
  description = "Private Onlyでない場合のPublic Network Access設定。"
}

variable "ai_network_default_action" {
  type        = string
  description = "Private Onlyでない場合のNetwork ACL既定アクション。"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Private Endpointを配置するSubnet ID。"
}

variable "ai_private_dns_zone_ids" {
  type        = map(string)
  description = "AI系Private DNS Zone IDのmap。"
}
