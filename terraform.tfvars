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

# Hub Azure FirewallのPrivate IPが確定したら設定します。
# 第1段階ではHub未接続の可能性があるため、UDR自体は無効にしています。
hub_firewall_private_ip    = "<Hub Firewall Private IP>"
enable_udr_to_hub_firewall = false

snet_aca_infra_name            = "snet-aca-infra"
snet_aca_infra_prefixes        = ["10.30.0.0/24"]
snet_private_endpoint_name     = "snet-private-endpoint"
snet_private_endpoint_prefixes = ["10.30.1.0/25"]
snet_admin_name                = "snet-admin"
snet_admin_prefixes            = ["10.30.1.128/28"]

ai_name         = "ai-ocr-demo-dev"
ai_location     = "japaneast"
ai_sku_name     = "S0"
ai_project_name = "proj-default"

# 閉域確認用の設定です。trueの場合、Public Network Accessを無効化し、既定アクションをDenyにします。
enable_ai_private_only_access = true

ai_public_network_access_enabled = true
ai_network_default_action        = "Allow"

log_analytics_workspace_name = "law-ocr-demo-dev"
log_analytics_retention_days = 30

# Blob Storage
create_storage_account = true

# Storage Account名はAzure全体で一意にする必要があります。
storage_account_name             = "stocrocrdemodev001"
storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"
storage_account_access_tier      = "Hot"

enable_storage_private_only_access = true

# enable_storage_private_only_accessがfalseの場合だけ使う値です。
storage_public_network_access_enabled = true
storage_network_default_action        = "Allow"
storage_network_bypass                = ["AzureServices"]

# PoCではCloud ShellからTerraformを通すため、一時的にShared Key認証を許可します。
# これはPublic Network Accessを開ける設定ではありません。
storage_shared_access_key_enabled = true

# Private Only StorageではCloud ShellからBlob Container作成が失敗する可能性があるため、第1段階では作成しません。
blob_container_name   = "documents"
create_blob_container = false

# Key Vault
create_key_vault = true

# Key Vault名はAzure全体で一意にする必要があります。
key_vault_name     = "kv-ocr-demo-dev-001"
key_vault_sku_name = "standard"

enable_key_vault_private_only_access = true

# enable_key_vault_private_only_accessがfalseの場合だけ使う値です。
key_vault_public_network_access_enabled = true
key_vault_network_default_action        = "Allow"
key_vault_network_bypass                = "AzureServices"

key_vault_soft_delete_retention_days = 7
key_vault_purge_protection_enabled   = false

# 管理VMは第1段階で作成します。Public IPは付けません。
create_admin_vm          = true
admin_vm_name            = "vm-ocr-demo-dev-admin"
admin_vm_size            = "Standard_B1s"
admin_username           = "azureuser"
admin_private_ip_address = "10.30.1.132"

# create_admin_vmがtrueの場合は必須です。秘密鍵ではなくSSH公開鍵だけを設定します。
admin_ssh_public_key = null

# 第1段階ではHub未接続の可能性があるためnullで構いません。
# nullの場合、管理VM用NSGは作成しますがSSH許可ルールは作成しません。
hub_azure_bastion_subnet_prefix = null
