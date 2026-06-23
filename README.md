# OCR Demo Terraform

Azure OCR-Demo PoC 用の Terraform です。使い回しやすいように、第1フェーズの閉域基盤と、第2フェーズのアプリ基盤を分けています。

## 構成

- `01-foundation-network-ai`: Resource Group、VNet、Subnet、Azure AI Foundry、Blob Storage、Key Vault、Private Endpoint、Private DNS、Log Analytics、管理VM
- `02-app`: ACR、User Assigned Managed Identity、Container Apps Environment、API/UI Container App、Role Assignment

## 第1フェーズのネットワーク

`01-foundation-network-ai/terraform.tfvars` の既定ネットワークは以下です。

```hcl
vnet_address_space = ["10.30.0.0/22"]

snet_aca_infra_prefixes        = ["10.30.0.0/23"]
snet_private_endpoint_prefixes = ["10.30.2.0/24"]
snet_admin_prefixes            = ["10.30.3.0/27"]

admin_private_ip_address = "10.30.3.10"
```

予備領域として `10.30.3.32` から `10.30.3.255` を残しています。

## 実行順

先に `01-foundation-network-ai` を実行します。

```powershell
cd 01-foundation-network-ai
terraform init
terraform fmt
terraform validate
terraform plan -out main.tfplan
terraform apply main.tfplan
```

その後、ACR にイメージを作成します。

```powershell
az acr build --registry <acr_name> --image ocr-demo-api:v1 ./src/backend
az acr build --registry <acr_name> --image ocr-demo-ui:v1 ./src/ui
```

最後に `02-app` を実行します。

```powershell
cd ../02-app
terraform init
terraform fmt
terraform validate
terraform plan -out main.tfplan
terraform apply main.tfplan
```

## 必ず確認する変数

環境ごとに最低限、以下を確認してください。

| ファイル | 変数 | 説明 |
|---|---|---|
| `01-foundation-network-ai/terraform.tfvars` | `subscription_id` | Azure CLI の既定サブスクリプションを使う場合は `null` のままで可。 |
| `01-foundation-network-ai/terraform.tfvars` | `location` / `ai_location` | 既定は `japaneast`。 |
| `01-foundation-network-ai/terraform.tfvars` | `resource_group_name` | 既定は `rg-ocr-demo-dev`。 |
| `01-foundation-network-ai/terraform.tfvars` | `storage_account_name` | Azure 全体で一意。英小文字と数字のみ、3-24文字。 |
| `01-foundation-network-ai/terraform.tfvars` | `key_vault_name` | Azure 全体で一意。 |
| `01-foundation-network-ai/terraform.tfvars` | `hub_firewall_private_ip` | Hub Azure Firewall の Private IP。第1段階では UDR 無効でも値を保持できます。 |
| `01-foundation-network-ai/terraform.tfvars` | `enable_udr_to_hub_firewall` | 第1段階は `false`。Hub 接続後に `true` へ変更します。 |
| `01-foundation-network-ai/terraform.tfvars` | `hub_azure_bastion_subnet_prefix` | 管理VMへのSSH許可元。Hub 側 `AzureBastionSubnet` の CIDR。 |
| `01-foundation-network-ai/terraform.tfvars` | `admin_ssh_public_key` | 管理VMのSSH公開鍵。 |
| `02-app/terraform.tfvars` | `acr_name` | Azure 全体で一意。英小文字と数字のみ。 |

## 閉域設定

第1フェーズは Private Endpoint 経由の閉域確認を優先します。

```hcl
enable_ai_private_only_access        = true
enable_storage_private_only_access   = true
enable_key_vault_private_only_access = true
```

PoC 継続のため、Storage Account は一時的に Shared Key 認証を許可しています。これは Public Network Access を開ける設定ではありません。

```hcl
storage_shared_access_key_enabled = true
```

本番寄せでは、アプリの Managed Identity と RBAC へ移行したうえで `false` に戻す想定です。

## 管理VM

管理VMは第1段階で作成します。

```hcl
create_admin_vm = true
```

Public IP は付けません。`snet-admin` に静的 Private IP `10.30.3.10` を割り当てます。

実行前に以下を自分の環境に合わせて設定してください。

```hcl
admin_ssh_public_key = "<SSH公開鍵>"
```

`hub_azure_bastion_subnet_prefix` は任意です。第1段階でHub未接続の場合は `null` のままでよく、その場合SSH許可ルールは作成されません。値を入れるとHub側 Azure Bastion からのSSH許可ルールだけが追加されます。

SSH秘密鍵はTerraformに入れません。Terraformに入れるのはSSH公開鍵のみです。

## UDR

第1段階ではHub未接続のため、UDRは無効です。

```hcl
enable_udr_to_hub_firewall = false
hub_firewall_private_ip    = null
```

第2段階でHub接続後、`hub_firewall_private_ip` にHub Azure FirewallのPrivate IPを設定し、`enable_udr_to_hub_firewall = true` にします。UDRを有効化しても、Route Tableを関連付けるのは `snet-aca-infra` と `snet-admin` のみです。`snet-private-endpoint` には関連付けません。

## 注意

VNet や Subnet の CIDR を変更すると、既存 Azure リソースがある場合は作り直しになる可能性があります。PoC 環境を作り直してよい場合は、既存 Resource Group を削除してから fresh apply する方が安全です。
