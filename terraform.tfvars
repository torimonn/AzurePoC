subscription_id = null

env         = "dev"
location    = "japaneast"
name_prefix = "ocr-demo"

resource_group_name = "rg-ocr-demo-dev"

tags = {
  app     = "ocr-demo"
  env     = "dev"
  owner   = "toshiki"
  purpose = "hands-on"
}

vnet_name          = "vnet-ocr-demo-dev"
vnet_address_space = ["10.30.0.0/23"]
dns_servers        = []

# Set the actual Hub Azure Firewall private IP when it is available.
# UDR itself is disabled in phase 1 because the Hub may not be connected yet.
hub_firewall_private_ip    = "<Hub Firewall Private IP>"
enable_udr_to_hub_firewall = false

snet_aca_infra_name             = "snet-aca-infra"
snet_aca_infra_prefixes         = ["10.30.0.0/24"]
snet_private_endpoint_name      = "snet-private-endpoint"
snet_private_endpoint_prefixes  = ["10.30.1.0/25"]
snet_admin_name                 = "snet-admin"
snet_admin_prefixes             = ["10.30.1.128/28"]

ai_name         = "ai-ocr-demo-dev"
ai_location     = "japaneast"
ai_sku_name     = "S0"
ai_project_name = "proj-default"

# Private-only validation mode. This disables public network access and sets default action to Deny.
enable_ai_private_only_access = true

ai_public_network_access_enabled = true
ai_network_default_action        = "Allow"

log_analytics_workspace_name = "law-ocr-demo-dev"
log_analytics_retention_days = 30

# Blob Storage
create_storage_account = true

# Storage Account names must be globally unique in Azure.
storage_account_name             = "stocrocrdemodev001"
storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"
storage_account_access_tier      = "Hot"

enable_storage_private_only_access = true

# Used only when enable_storage_private_only_access is false.
storage_public_network_access_enabled = true
storage_network_default_action        = "Allow"
storage_network_bypass                = ["AzureServices"]

# Temporary PoC setting for Cloud Shell Terraform runs. This is not Public Network Access.
storage_shared_access_key_enabled = true

# Do not create Blob containers in phase 1 because private-only storage can block data-plane access from Cloud Shell.
blob_container_name   = "documents"
create_blob_container = false

# Key Vault
create_key_vault = true

# Key Vault names must be globally unique in Azure.
key_vault_name     = "kv-ocr-demo-dev-001"
key_vault_sku_name = "standard"

enable_key_vault_private_only_access = true

# Used only when enable_key_vault_private_only_access is false.
key_vault_public_network_access_enabled = true
key_vault_network_default_action        = "Allow"
key_vault_network_bypass                = "AzureServices"

key_vault_soft_delete_retention_days = 7
key_vault_purge_protection_enabled   = false

# Admin VM is created in phase 1 without a Public IP.
create_admin_vm          = true
admin_vm_name            = "vm-ocr-demo-dev-admin"
admin_vm_size            = "Standard_B1s"
admin_username           = "azureuser"
admin_private_ip_address = "10.30.1.132"

# Required when create_admin_vm is true. Put only the SSH public key here, never a private key.
admin_ssh_public_key = null

# Optional in phase 1. When null, the admin NSG is created but no SSH allow rule is created.
hub_azure_bastion_subnet_prefix = null
