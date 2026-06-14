variable "subscription_id" {
  description = "Azure subscription ID. Azure CLI の既定サブスクリプションを使う場合は null のままでも構いません。"
  type        = string
  default     = null
}

variable "env" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Default Azure region."
  type        = string
  default     = "japaneast"
}

variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
  default     = "ocr-demo"
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
  default     = "rg-ocr-demo-dev"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default = {
    app     = "ocr-demo"
    env     = "dev"
    purpose = "hands-on"
  }
}

variable "vnet_name" {
  description = "Virtual network name."
  type        = string
  default     = "vnet-ocr-demo-dev"
}

variable "vnet_address_space" {
  description = "Virtual network address space."
  type        = list(string)
  default     = ["10.30.0.0/21"]
}

variable "dns_servers" {
  description = "Custom DNS servers. Empty list uses Azure-provided DNS."
  type        = list(string)
  default     = []
}

variable "snet_aca_infra_name" {
  description = "Subnet name for Azure Container Apps environment."
  type        = string
  default     = "snet-aca-infra"
}

variable "snet_aca_infra_prefixes" {
  description = "Subnet CIDR for Azure Container Apps environment. /21 or larger is required when using infrastructure_subnet_id."
  type        = list(string)
  default     = ["10.30.0.0/23"]
}

variable "snet_private_endpoint_name" {
  description = "Subnet name for private endpoints."
  type        = string
  default     = "snet-private-endpoint"
}

variable "snet_private_endpoint_prefixes" {
  description = "Subnet CIDR for private endpoints."
  type        = list(string)
  default     = ["10.30.2.0/24"]
}

variable "snet_admin_name" {
  description = "Subnet name for optional admin VM."
  type        = string
  default     = "snet-admin"
}

variable "snet_admin_prefixes" {
  description = "Subnet CIDR for optional admin VM."
  type        = list(string)
  default     = ["10.30.3.0/27"]
}

variable "ai_name" {
  description = "Azure AI Foundry account name."
  type        = string
  default     = "ai-ocr-demo-dev"
}

variable "ai_location" {
  description = "Azure AI Foundry account region."
  type        = string
  default     = "japaneast"
}

variable "ai_sku_name" {
  description = "Azure AI Services SKU."
  type        = string
  default     = "S0"
}

variable "ai_project_name" {
  description = "Azure AI Foundry project name."
  type        = string
  default     = "proj-default"
}

variable "ai_public_network_access_enabled" {
  description = "Whether public network access is enabled for the AI account."
  type        = bool
  default     = true
}

variable "enable_ai_private_only_access" {
  description = "When true, AI public network access is disabled and network ACL default action is Deny."
  type        = bool
  default     = false
}

variable "ai_network_default_action" {
  description = "Network ACL default action for the AI account."
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.ai_network_default_action)
    error_message = "ai_network_default_action must be Allow or Deny."
  }
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics workspace name."
  type        = string
  default     = "law-ocr-demo-dev"
}

variable "log_analytics_retention_days" {
  description = "Log Analytics retention days."
  type        = number
  default     = 30
}

variable "create_storage_account" {
  description = "Whether to create Blob Storage account in foundation phase."
  type        = bool
  default     = true
}

variable "storage_account_name" {
  description = "Storage Account name. Must be globally unique, 3-24 characters, lowercase letters and numbers only."
  type        = string
  default     = "stocrocrdemodev001"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 characters and contain only lowercase letters and numbers."
  }
}

variable "storage_account_tier" {
  description = "Storage Account tier."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "storage_account_tier must be Standard or Premium."
  }
}

variable "storage_account_replication_type" {
  description = "Storage Account replication type."
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS", "RAGRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "storage_account_replication_type must be one of LRS, ZRS, GRS, GZRS, RAGRS, or RAGZRS."
  }
}

variable "storage_account_access_tier" {
  description = "Storage Account access tier."
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.storage_account_access_tier)
    error_message = "storage_account_access_tier must be Hot or Cool."
  }
}

variable "enable_storage_private_only_access" {
  description = "When true, Storage public network access is disabled and network default action is Deny."
  type        = bool
  default     = true
}

variable "storage_public_network_access_enabled" {
  description = "Whether public network access is enabled for Storage Account when enable_storage_private_only_access is false."
  type        = bool
  default     = true
}

variable "storage_network_default_action" {
  description = "Storage network default action when enable_storage_private_only_access is false."
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.storage_network_default_action)
    error_message = "storage_network_default_action must be Allow or Deny."
  }
}

variable "storage_network_bypass" {
  description = "Storage network bypass settings."
  type        = list(string)
  default     = ["AzureServices"]
}

variable "storage_shared_access_key_enabled" {
  description = "Whether shared key access is enabled for the Storage Account. Prefer false for production."
  type        = bool
  default     = false
}

variable "blob_container_name" {
  description = "Blob container name for application documents. The container is not created by default in foundation phase."
  type        = string
  default     = "documents"
}

variable "create_blob_container" {
  description = "Whether to create Blob container. Default false because private-only storage may block Terraform data-plane access from outside VNet."
  type        = bool
  default     = false
}

variable "create_key_vault" {
  description = "Whether to create Key Vault in foundation phase."
  type        = bool
  default     = true
}

variable "key_vault_name" {
  description = "Key Vault name. Must be globally unique."
  type        = string
  default     = "kv-ocr-demo-dev-001"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.key_vault_name)) && !can(regex("--", var.key_vault_name))
    error_message = "key_vault_name must be 3-24 characters, start with a letter, end with a letter or number, and contain only letters, numbers, and hyphens without consecutive hyphens."
  }
}

variable "key_vault_sku_name" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku_name)
    error_message = "key_vault_sku_name must be standard or premium."
  }
}

variable "enable_key_vault_private_only_access" {
  description = "When true, Key Vault public network access is disabled and network ACL default action is Deny."
  type        = bool
  default     = true
}

variable "key_vault_public_network_access_enabled" {
  description = "Whether public network access is enabled for Key Vault when enable_key_vault_private_only_access is false."
  type        = bool
  default     = true
}

variable "key_vault_network_default_action" {
  description = "Key Vault network ACL default action when enable_key_vault_private_only_access is false."
  type        = string
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.key_vault_network_default_action)
    error_message = "key_vault_network_default_action must be Allow or Deny."
  }
}

variable "key_vault_network_bypass" {
  description = "Key Vault network ACL bypass setting."
  type        = string
  default     = "AzureServices"

  validation {
    condition     = contains(["AzureServices", "None"], var.key_vault_network_bypass)
    error_message = "key_vault_network_bypass must be AzureServices or None."
  }
}

variable "key_vault_soft_delete_retention_days" {
  description = "Soft delete retention days for Key Vault."
  type        = number
  default     = 7

  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "key_vault_soft_delete_retention_days must be between 7 and 90."
  }
}

variable "key_vault_purge_protection_enabled" {
  description = "Whether purge protection is enabled. Recommended true for production."
  type        = bool
  default     = false
}

variable "create_admin_vm" {
  description = "Whether to create an admin VM for private network validation."
  type        = bool
  default     = true
}

variable "admin_vm_name" {
  description = "Optional admin VM name."
  type        = string
  default     = "vm-ocr-demo-dev-admin"
}

variable "admin_vm_size" {
  description = "Optional admin VM size."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin VM username."
  type        = string
  default     = "azureuser"
}

variable "admin_private_ip_address" {
  description = "Static private IP address for the optional admin VM."
  type        = string
  default     = "10.30.3.10"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for the optional admin VM. Required when create_admin_vm is true."
  type        = string
  default     = null
  sensitive   = true
}

variable "hub_azure_bastion_subnet_prefix" {
  description = "Hub-side AzureBastionSubnet CIDR allowed to SSH to the optional admin VM."
  type        = string
  default     = null
}
