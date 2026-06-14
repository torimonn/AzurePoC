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
vnet_address_space = ["10.30.0.0/21"]
dns_servers        = []

snet_aca_infra_name          = "snet-aca-infra"
snet_aca_infra_prefixes      = ["10.30.0.0/23"]
snet_private_endpoint_name   = "snet-private-endpoint"
snet_private_endpoint_prefixes = ["10.30.2.0/24"]
snet_admin_name              = "snet-admin"
snet_admin_prefixes          = ["10.30.3.0/27"]

ai_name         = "ai-ocr-demo-dev"
ai_location     = "japaneast"
ai_sku_name     = "S0"
ai_project_name = "proj-default"

# 閉域確認時は true。Portal/疎通切り分けで一時的に公開許可したい場合は false にします。
enable_ai_private_only_access = true

ai_public_network_access_enabled = true
ai_network_default_action        = "Allow"

log_analytics_workspace_name = "law-ocr-demo-dev"
log_analytics_retention_days = 30

# Blob Storage
create_storage_account = true

# Storage Account名はAzure全体で一意にする必要があります。
# 名前が重複した場合は末尾の数字などを変更してください。
storage_account_name             = "stocrocrdemodev001"
storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"
storage_account_access_tier      = "Hot"

# 閉域確認時はtrue。
# trueの場合、public_network_access_enabled=false、network default action=Denyになります。
enable_storage_private_only_access = true

# enable_storage_private_only_access=false のときだけ使う値です。
storage_public_network_access_enabled = true
storage_network_default_action        = "Allow"
storage_network_bypass                = ["AzureServices"]

# PoCではCloud ShellからTerraformを通すため一時的にtrue。
# 本番ではfalse推奨。Managed Identity + RBACでBlobにアクセスする想定です。
storage_shared_access_key_enabled = true

# 第1フェーズではコンテナ作成は原則しません。
blob_container_name   = "documents"
create_blob_container = false

# Key Vault
create_key_vault = true

# Key Vault名もAzure全体で一意にする必要があります。
# 名前が重複した場合は末尾の数字などを変更してください。
key_vault_name     = "kv-ocr-demo-dev-001"
key_vault_sku_name = "standard"

# 閉域確認時はtrue。
# trueの場合、public_network_access_enabled=false、network ACL default action=Denyになります。
enable_key_vault_private_only_access = true

# enable_key_vault_private_only_access=false のときだけ使う値です。
key_vault_public_network_access_enabled = true
key_vault_network_default_action        = "Allow"
key_vault_network_bypass                = "AzureServices"

key_vault_soft_delete_retention_days = 7

# PoCではfalseでもよい。本番ではtrue推奨。
key_vault_purge_protection_enabled = false

# 閉域疎通確認用の管理VM。Public IPは付けず、Hub側Azure BastionからSSHします。
create_admin_vm             = true
admin_vm_name               = "vm-ocr-demo-dev-admin"
admin_vm_size               = "Standard_B1s"
admin_username              = "azureuser"
admin_private_ip_address    = "10.30.3.10"
admin_ssh_public_key        = null

# Hub側AzureBastionSubnetのCIDRを指定します。例: "10.0.1.0/26"
hub_azure_bastion_subnet_prefix = null
