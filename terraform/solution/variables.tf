variable "subscription_id" {
  description = "AzureサブスクリプションID。Azure CLIの現在のサブスクリプションを使う場合はnullにします。"
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
  description = "OCR-Demo Resource Group名。"
  type        = string
  default     = "rg-ocr-demo-dev"
}

variable "tags" {
  description = "全リソースへ付与する共通タグ。"
  type        = map(string)
  default = {
    app     = "ocr-demo"
    env     = "dev"
    purpose = "hands-on"
  }
}

variable "vnet_name" {
  description = "Spoke Virtual Network名。"
  type        = string
  default     = "vnet-ocr-demo-dev"
}

variable "vnet_address_space" {
  description = "Spoke Virtual Networkのアドレス空間。"
  type        = list(string)
  default     = ["10.30.0.0/24"]
}

variable "dns_servers" {
  description = "Spoke VNetのカスタムDNSサーバー。空配列の場合はAzure提供DNSを使用します。"
  type        = list(string)
  default     = []
}

variable "snet_aca_infra_name" {
  description = "将来のAzure Container Apps Workload profiles環境用Subnet名。"
  type        = string
  default     = "snet-aca-infra"
}

variable "snet_aca_infra_prefixes" {
  description = "Azure Container Apps用Subnet CIDR。"
  type        = list(string)
  default     = ["10.30.0.0/25"]
}

variable "snet_private_endpoint_name" {
  description = "Private Endpoint用Subnet名。"
  type        = string
  default     = "snet-private-endpoint"
}

variable "snet_private_endpoint_prefixes" {
  description = "Private Endpoint用Subnet CIDR。"
  type        = list(string)
  default     = ["10.30.0.128/26"]
}

variable "snet_admin_name" {
  description = "管理VM用Subnet名。"
  type        = string
  default     = "snet-admin"
}

variable "snet_admin_prefixes" {
  description = "管理VM用Subnet CIDR。"
  type        = list(string)
  default     = ["10.30.0.192/28"]
}

variable "enable_udr_to_hub_firewall" {
  description = "ACA用Subnetと管理VM用SubnetをHub Firewallへ向けるRoute Tableを作成するかどうか。"
  type        = bool
  default     = false
}

variable "hub_firewall_private_ip" {
  description = "UDRのNext Hopに使うHub Azure FirewallのPrivate IP。UDR無効時はnullでも構いません。"
  type        = string
  default     = null

  validation {
    condition     = !var.enable_udr_to_hub_firewall || var.hub_firewall_private_ip != null
    error_message = "enable_udr_to_hub_firewallがtrueの場合、hub_firewall_private_ipが必要です。"
  }
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics Workspace名。"
  type        = string
  default     = "law-ocr-demo-dev"
}

variable "log_analytics_retention_days" {
  description = "Log Analytics Workspaceの保持日数。"
  type        = number
  default     = 30
}

variable "ai_name" {
  description = "Azure AI Servicesアカウント名。custom subdomainにも使用します。"
  type        = string
  default     = "ai-ocr-demo-dev"
}

variable "ai_location" {
  description = "Azure AI ServicesのAzureリージョン。"
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

variable "enable_ai_private_only_access" {
  description = "trueの場合、AI ServicesのPublic Network Accessを無効化し、Network ACLをDenyにします。"
  type        = bool
  default     = true
}

variable "ai_public_network_access_enabled" {
  description = "enable_ai_private_only_accessがfalseの場合に使うAI ServicesのPublic Network Access設定。"
  type        = bool
  default     = true
}

variable "ai_network_default_action" {
  description = "enable_ai_private_only_accessがfalseの場合に使うAI Services Network ACLの既定アクション。"
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.ai_network_default_action)
    error_message = "ai_network_default_actionはAllowまたはDenyを指定してください。"
  }
}

variable "create_storage_account" {
  description = "第1段階でアプリ用Storage Accountを作成するかどうか。"
  type        = bool
  default     = true
}

variable "storage_account_name" {
  description = "アプリ用Storage Account名。Azure全体で一意、3～24文字、英小文字と数字のみです。"
  type        = string
  default     = "stocrocrdemodev001"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_nameは3～24文字の英小文字と数字だけで指定してください。"
  }
}

variable "storage_account_tier" {
  description = "Storage AccountのTier。"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "storage_account_tierはStandardまたはPremiumを指定してください。"
  }
}

variable "storage_account_replication_type" {
  description = "Storage Accountの冗長化方式。"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS", "RAGRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "storage_account_replication_typeの値が不正です。"
  }
}

variable "storage_account_access_tier" {
  description = "Storage AccountのAccess Tier。"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.storage_account_access_tier)
    error_message = "storage_account_access_tierはHotまたはCoolを指定してください。"
  }
}

variable "enable_storage_private_only_access" {
  description = "trueの場合、Storage AccountのPublic Network Accessを無効化し、Network RuleをDenyにします。"
  type        = bool
  default     = true
}

variable "storage_public_network_access_enabled" {
  description = "enable_storage_private_only_accessがfalseの場合に使うStorage AccountのPublic Network Access設定。"
  type        = bool
  default     = true
}

variable "storage_network_default_action" {
  description = "enable_storage_private_only_accessがfalseの場合に使うStorage Network Ruleの既定アクション。"
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.storage_network_default_action)
    error_message = "storage_network_default_actionはAllowまたはDenyを指定してください。"
  }
}

variable "storage_network_bypass" {
  description = "Storage Network Ruleのバイパス設定。"
  type        = set(string)
  default     = ["AzureServices"]
}

variable "storage_shared_access_key_enabled" {
  description = "Storage AccountのShared Key認証。第1段階PoCでは一時的にtrueとします。"
  type        = bool
  default     = true
}

variable "blob_container_name" {
  description = "第3段階以降に作成するアプリ用Blob Container名。第1段階では作成しません。"
  type        = string
  default     = "documents"
}

variable "create_blob_container" {
  description = "第1段階でBlob Containerを作成するかどうか。第1段階ではfalse固定です。"
  type        = bool
  default     = false

  validation {
    condition     = !var.create_blob_container
    error_message = "第1段階ではcreate_blob_containerをfalseにしてください。"
  }
}

variable "enable_state_storage_private_endpoint" {
  description = "管理VM移行後にTerraform state用Storage AccountのBlob Private Endpointを作成するかどうか。初期Cloud Shell構築ではfalseにします。"
  type        = bool
  default     = false
}

variable "state_storage_account_id" {
  description = "bootstrapが作成したTerraform state用Storage AccountのResource ID。State Storage Private Endpoint有効時に必須です。"
  type        = string
  default     = null

  validation {
    condition     = !var.enable_state_storage_private_endpoint || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Storage/storageAccounts/[^/]+$", var.state_storage_account_id))
    error_message = "enable_state_storage_private_endpointがtrueの場合、有効なstate_storage_account_idが必要です。"
  }
}

variable "state_storage_account_name" {
  description = "bootstrapが作成したTerraform state用Storage Account名。State Storage Private Endpoint有効時に必須です。"
  type        = string
  default     = null

  validation {
    condition     = !var.enable_state_storage_private_endpoint || can(regex("^[a-z0-9]{3,24}$", var.state_storage_account_name))
    error_message = "enable_state_storage_private_endpointがtrueの場合、3～24文字の英小文字と数字で構成されたstate_storage_account_nameが必要です。"
  }
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
    error_message = "key_vault_nameは3～24文字で、先頭は英字、末尾は英数字、連続ハイフンなしで指定してください。"
  }
}

variable "key_vault_sku_name" {
  description = "Key VaultのSKU。"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku_name)
    error_message = "key_vault_sku_nameはstandardまたはpremiumを指定してください。"
  }
}

variable "enable_key_vault_private_only_access" {
  description = "trueの場合、Key VaultのPublic Network Accessを無効化し、Network ACLをDenyにします。"
  type        = bool
  default     = true
}

variable "key_vault_public_network_access_enabled" {
  description = "enable_key_vault_private_only_accessがfalseの場合に使うKey VaultのPublic Network Access設定。"
  type        = bool
  default     = true
}

variable "key_vault_network_default_action" {
  description = "enable_key_vault_private_only_accessがfalseの場合に使うKey Vault Network ACLの既定アクション。"
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.key_vault_network_default_action)
    error_message = "key_vault_network_default_actionはAllowまたはDenyを指定してください。"
  }
}

variable "key_vault_network_bypass" {
  description = "Key Vault Network ACLのバイパス設定。"
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["AzureServices", "None"], var.key_vault_network_bypass)
    error_message = "key_vault_network_bypassはAzureServicesまたはNoneを指定してください。"
  }
}

variable "key_vault_soft_delete_retention_days" {
  description = "Key VaultのSoft Delete保持日数。"
  type        = number
  default     = 7

  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "key_vault_soft_delete_retention_daysは7～90日で指定してください。"
  }
}

variable "key_vault_purge_protection_enabled" {
  description = "Key VaultのPurge Protection。PoCではfalse、本番ではtrueを推奨します。"
  type        = bool
  default     = false
}

variable "create_admin_vm" {
  description = "閉域疎通確認用の管理VMを作成するかどうか。"
  type        = bool
  default     = true
}

variable "enable_admin_vm_entra_id_login" {
  description = "管理VMへAADSSHLoginForLinux拡張を導入し、Microsoft Entra ID SSH認証を有効にするかどうか。"
  type        = bool
  default     = true
}

variable "admin_vm_login_principal_id" {
  description = "Virtual Machine Administrator LoginをResource Groupへ付与するMicrosoft EntraユーザーまたはグループのObject ID。nullの場合はRole Assignmentを作成しません。"
  type        = string
  default     = null

  validation {
    condition     = var.admin_vm_login_principal_id == null || can(regex("^[0-9a-fA-F-]{36}$", var.admin_vm_login_principal_id))
    error_message = "admin_vm_login_principal_idは有効なMicrosoft Entra Object IDまたはnullにしてください。"
  }
}

variable "admin_vm_login_principal_type" {
  description = "管理VMログインRoleを付与するプリンシパル種別。User、Group、ServicePrincipal、またはnullを指定します。"
  type        = string
  default     = null

  validation {
    condition     = var.admin_vm_login_principal_type == null || contains(["User", "Group", "ServicePrincipal"], var.admin_vm_login_principal_type)
    error_message = "admin_vm_login_principal_typeはUser、Group、ServicePrincipal、またはnullにしてください。"
  }
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
  description = "管理VMの管理ユーザー名。"
  type        = string
  default     = "azureuser"
}

variable "admin_private_ip_address" {
  description = "管理VMへ割り当てる固定Private IP。"
  type        = string
  default     = "10.30.0.196"
}

variable "admin_ssh_public_key" {
  description = "管理VM用の内部break-glass SSH公開鍵。秘密鍵は指定しません。"
  type        = string
  sensitive   = true

  validation {
    condition     = !var.create_admin_vm || (var.admin_ssh_public_key != null && can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp)", trimspace(var.admin_ssh_public_key))))
    error_message = "create_admin_vmがtrueの場合、有効なadmin_ssh_public_keyが必要です。"
  }
}

variable "hub_azure_bastion_subnet_prefix" {
  description = "管理VMへのSSHを許可するHub AzureBastionSubnetのCIDR。nullの場合はSSH許可ルールを作成しません。"
  type        = string
  default     = null
}
