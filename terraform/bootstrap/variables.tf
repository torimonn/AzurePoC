variable "subscription_id" {
  description = "AzureサブスクリプションID。Azure CLIの現在のサブスクリプションを使う場合はnullにします。"
  type        = string
  default     = null
}

variable "location" {
  description = "state基盤を作成するAzureリージョン。"
  type        = string
  default     = "japaneast"
}

variable "state_resource_group_name" {
  description = "Terraform state用Resource Group名。"
  type        = string
  default     = "rg-ocr-demo-tfstate"
}

variable "state_storage_account_name" {
  description = "Terraform state用Storage Account名。Azure全体で一意にする必要があります。"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.state_storage_account_name))
    error_message = "state_storage_account_nameは3～24文字の英小文字と数字だけで指定してください。"
  }
}

variable "state_storage_account_sku_name" {
  description = "Terraform state用Storage AccountのSKU。"
  type        = string
  default     = "Standard_LRS"
}

variable "state_container_name" {
  description = "Terraform stateを保存するBlob Container名。"
  type        = string
  default     = "tfstate"
}

variable "state_public_network_access_enabled" {
  description = "初期bootstrap時にstate StorageのPublic Network Accessを有効にするかどうか。閉域経路の準備後に見直します。"
  type        = bool
  default     = true
}

variable "state_network_default_action" {
  description = "state StorageのNetwork Rule既定アクション。Cloud Shellからの初期構築ではAllowを使用します。"
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.state_network_default_action)
    error_message = "state_network_default_actionはAllowまたはDenyを指定してください。"
  }
}

variable "state_network_bypass" {
  description = "state StorageのNetwork Ruleでバイパスを許可するサービス。"
  type        = set(string)
  default     = ["AzureServices"]
}

variable "grant_current_principal_blob_data_contributor" {
  description = "bootstrap実行者へStorage Blob Data Contributorを付与するかどうか。"
  type        = bool
  default     = true
}

variable "state_admin_principal_id" {
  description = "state StorageへStorage Blob Data Contributorを付与するMicrosoft EntraプリンシパルのObject ID。"
  type        = string

  validation {
    condition     = !var.grant_current_principal_blob_data_contributor || (var.state_admin_principal_id != null && can(regex("^[0-9a-fA-F-]{36}$", var.state_admin_principal_id)))
    error_message = "RBACを作成する場合、有効なstate_admin_principal_idが必要です。"
  }
}

variable "tags" {
  description = "state基盤へ付与する共通タグ。"
  type        = map(string)
  default = {
    app     = "ocr-demo"
    env     = "shared"
    purpose = "terraform-state"
  }
}
