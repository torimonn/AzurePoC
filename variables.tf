variable "subscription_id" {
  description = "AzureサブスクリプションID。現在のAzure CLIサブスクリプションを使う場合はnullのままで構いません。"
  type        = string
  default     = null
}

variable "env" {
  description = "環境名。"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "既定のAzureリージョン。"
  type        = string
  default     = "japaneast"
}

variable "name_prefix" {
  description = "リソース名に使う共通プレフィックス。"
  type        = string
  default     = "ocr-demo"
}

variable "resource_group_name" {
  description = "Resource Group名。"
  type        = string
  default     = "rg-ocr-demo-dev"
}

variable "tags" {
  description = "共通タグ。"
  type        = map(string)
  default = {
    app     = "ocr-demo"
    env     = "dev"
    purpose = "hands-on"
  }
}

variable "vnet_name" {
  description = "Virtual Network名。"
  type        = string
  default     = "vnet-ocr-demo-dev"
}

variable "vnet_address_space" {
  description = "Virtual Networkのアドレス空間。"
  type        = list(string)
  default     = ["10.30.0.0/23"]
}

variable "dns_servers" {
  description = "カスタムDNSサーバー。空配列の場合はAzure提供DNSを使用します。"
  type        = list(string)
  default     = []
}

variable "enable_udr_to_hub_firewall" {
  description = "Subnet通信をHub Firewallへ向けるRoute Tableを作成し、関連付けるかどうか。"
  type        = bool
  default     = false
}

variable "hub_firewall_private_ip" {
  description = "UDRのNext Hopに使うHub Azure FirewallのPrivate IP。第1段階でUDRを無効にしていても、値が確定したら設定します。"
  type        = string
  default     = null
}

variable "snet_aca_infra_name" {
  description = "Azure Container Apps Environment用Subnet名。"
  type        = string
  default     = "snet-aca-infra"
}

variable "snet_aca_infra_prefixes" {
  description = "将来のAzure Container Apps Workload profiles環境で使うSubnet CIDR。"
  type        = list(string)
  default     = ["10.30.0.0/24"]
}

variable "snet_private_endpoint_name" {
  description = "Private Endpoint用Subnet名。"
  type        = string
  default     = "snet-private-endpoint"
}

variable "snet_private_endpoint_prefixes" {
  description = "Private Endpoint用Subnet CIDR。"
  type        = list(string)
  default     = ["10.30.1.0/25"]
}

variable "snet_admin_name" {
  description = "管理VM用Subnet名。"
  type        = string
  default     = "snet-admin"
}

variable "snet_admin_prefixes" {
  description = "管理VM用Subnet CIDR。"
  type        = list(string)
  default     = ["10.30.1.128/28"]
}

variable "ai_name" {
  description = "Azure AI Services / Foundryアカウント名。"
  type        = string
  default     = "ai-ocr-demo-dev"
}

variable "ai_location" {
  description = "Azure AI Services / Foundryアカウントのリージョン。"
  type        = string
  default     = "japaneast"
}

variable "ai_sku_name" {
  description = "Azure AI ServicesのSKU。"
  type        = string
  default     = "S0"
}

variable "ai_project_name" {
  description = "Azure AI Foundry Project名。"
  type        = string
  default     = "proj-default"
}

variable "ai_public_network_access_enabled" {
  description = "enable_ai_private_only_accessがfalseの場合に、AIアカウントのPublic Network Accessを有効にするかどうか。"
  type        = bool
  default     = true
}

variable "enable_ai_private_only_access" {
  description = "trueの場合、AIアカウントのPublic Network Accessを無効化し、Network ACLの既定アクションをDenyにします。"
  type        = bool
  default     = false
}

variable "ai_network_default_action" {
  description = "AIアカウントのNetwork ACL既定アクション。"
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.ai_network_default_action)
    error_message = "ai_network_default_action must be Allow or Deny."
  }
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics Workspace名。"
  type        = string
  default     = "law-ocr-demo-dev"
}

variable "log_analytics_retention_days" {
  description = "Log Analyticsの保持日数。"
  type        = number
  default     = 30
}

variable "create_storage_account" {
  description = "第1段階でBlob Storage用Storage Accountを作成するかどうか。"
  type        = bool
  default     = true
}

variable "storage_account_name" {
  description = "Storage Account名。Azure全体で一意、3-24文字、英小文字と数字のみです。"
  type        = string
  default     = "stocrocrdemodev001"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 characters and contain only lowercase letters and numbers."
  }
}

variable "storage_account_tier" {
  description = "Storage AccountのTier。"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "storage_account_tier must be Standard or Premium."
  }
}

variable "storage_account_replication_type" {
  description = "Storage Accountの冗長化方式。"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS", "RAGRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "storage_account_replication_type must be one of LRS, ZRS, GRS, GZRS, RAGRS, or RAGZRS."
  }
}

variable "storage_account_access_tier" {
  description = "Storage AccountのAccess Tier。"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.storage_account_access_tier)
    error_message = "storage_account_access_tier must be Hot or Cool."
  }
}

variable "enable_storage_private_only_access" {
  description = "trueの場合、Storage AccountのPublic Network Accessを無効化し、Network Ruleの既定アクションをDenyにします。"
  type        = bool
  default     = true
}

variable "storage_public_network_access_enabled" {
  description = "enable_storage_private_only_accessがfalseの場合に、Storage AccountのPublic Network Accessを有効にするかどうか。"
  type        = bool
  default     = true
}

variable "storage_network_default_action" {
  description = "enable_storage_private_only_accessがfalseの場合に使うStorage Network Ruleの既定アクション。"
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.storage_network_default_action)
    error_message = "storage_network_default_action must be Allow or Deny."
  }
}

variable "storage_network_bypass" {
  description = "Storage AccountのNetwork Ruleで許可するバイパス設定。"
  type        = list(string)
  default     = ["AzureServices"]
}

variable "storage_shared_access_key_enabled" {
  description = "Storage AccountのShared Key認証を有効にするかどうか。本番ではfalseを推奨します。"
  type        = bool
  default     = false
}

variable "blob_container_name" {
  description = "アプリ用Blob Container名。第1段階では既定で作成しません。"
  type        = string
  default     = "documents"
}

variable "create_blob_container" {
  description = "Blob Containerを作成するかどうか。Private Only StorageではTerraform実行元からデータプレーンアクセスできない可能性があるため、既定はfalseです。"
  type        = bool
  default     = false
}

variable "create_key_vault" {
  description = "第1段階でKey Vaultを作成するかどうか。"
  type        = bool
  default     = true
}

variable "key_vault_name" {
  description = "Key Vault名。Azure全体で一意にする必要があります。"
  type        = string
  default     = "kv-ocr-demo-dev-001"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.key_vault_name)) && !can(regex("--", var.key_vault_name))
    error_message = "key_vault_name must be 3-24 characters, start with a letter, end with a letter or number, and contain only letters, numbers, and hyphens without consecutive hyphens."
  }
}

variable "key_vault_sku_name" {
  description = "Key VaultのSKU。"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku_name)
    error_message = "key_vault_sku_name must be standard or premium."
  }
}

variable "enable_key_vault_private_only_access" {
  description = "trueの場合、Key VaultのPublic Network Accessを無効化し、Network ACLの既定アクションをDenyにします。"
  type        = bool
  default     = true
}

variable "key_vault_public_network_access_enabled" {
  description = "enable_key_vault_private_only_accessがfalseの場合に、Key VaultのPublic Network Accessを有効にするかどうか。"
  type        = bool
  default     = true
}

variable "key_vault_network_default_action" {
  description = "enable_key_vault_private_only_accessがfalseの場合に使うKey Vault Network ACLの既定アクション。"
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.key_vault_network_default_action)
    error_message = "key_vault_network_default_action must be Allow or Deny."
  }
}

variable "key_vault_network_bypass" {
  description = "Key Vault Network ACLのバイパス設定。"
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["AzureServices", "None"], var.key_vault_network_bypass)
    error_message = "key_vault_network_bypass must be AzureServices or None."
  }
}

variable "key_vault_soft_delete_retention_days" {
  description = "Key VaultのSoft Delete保持日数。"
  type        = number
  default     = 7

  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "key_vault_soft_delete_retention_days must be between 7 and 90."
  }
}

variable "key_vault_purge_protection_enabled" {
  description = "Key VaultのPurge Protectionを有効にするかどうか。本番ではtrueを推奨します。"
  type        = bool
  default     = false
}

variable "create_admin_vm" {
  description = "閉域疎通確認用の管理VMを作成するかどうか。"
  type        = bool
  default     = true
}

variable "admin_vm_name" {
  description = "管理VM名。"
  type        = string
  default     = "vm-ocr-demo-dev-admin"
}

variable "admin_vm_size" {
  description = "管理VMのサイズ。"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "管理VMのユーザー名。"
  type        = string
  default     = "azureuser"
}

variable "admin_private_ip_address" {
  description = "管理VMに割り当てる固定Private IP。"
  type        = string
  default     = "10.30.1.132"
}

variable "admin_ssh_public_key" {
  description = "管理VM用SSH公開鍵。create_admin_vmがtrueの場合は必須です。"
  type        = string
  default     = null
  sensitive   = true
}

variable "hub_azure_bastion_subnet_prefix" {
  description = "管理VMへのSSHを許可するHub側AzureBastionSubnetのCIDR。第1段階でSSH許可ルールを作成しない場合はnullにします。"
  type        = string
  default     = null
}
