# OCR Demo Terraform

Azure OCR-Demo PoC 用の Terraform コードです。使い回しやすいように、第1段階の閉域基盤と、後続のアプリ基盤を分けています。

## 構成

- `01-foundation-network-ai`: Resource Group、VNet、Subnet、Azure AI Services / Foundry Project、Blob Storage、Key Vault、Private Endpoint、Private DNS Zone、Log Analytics、Public IPなしの管理VMを作成します。
- `02-app`: 後続フェーズで、ACR、Managed Identity、Container Apps、Role Assignment、API、UIを作成する想定です。

## 第1段階のネットワーク

`01-foundation-network-ai/terraform.tfvars` のネットワークは、IPを節約するため小さめの `/23` 構成にしています。

```hcl
vnet_address_space = ["10.30.0.0/23"]

snet_aca_infra_prefixes        = ["10.30.0.0/24"]
snet_private_endpoint_prefixes = ["10.30.1.0/25"]
snet_admin_prefixes            = ["10.30.1.128/28"]

admin_private_ip_address = "10.30.1.132"
```

`10.30.1.144` から `10.30.1.255` は将来用の予備として残しています。

## 実行前に確認する値

環境ごとに、最低限以下を確認してください。

| ファイル | 変数 | 説明 |
|---|---|---|
| `01-foundation-network-ai/terraform.tfvars` | `subscription_id` | Azure CLIの現在のサブスクリプションを使う場合は `null` のままで構いません。 |
| `01-foundation-network-ai/terraform.tfvars` | `storage_account_name` | Azure全体で一意にする必要があります。英小文字と数字のみ、3-24文字です。 |
| `01-foundation-network-ai/terraform.tfvars` | `key_vault_name` | Azure全体で一意にする必要があります。 |
| `01-foundation-network-ai/terraform.tfvars` | `admin_ssh_public_key` | `create_admin_vm = true` の場合は必須です。秘密鍵ではなくSSH公開鍵だけを設定してください。 |
| `01-foundation-network-ai/terraform.tfvars` | `hub_azure_bastion_subnet_prefix` | 第1段階では `null` でも構いません。値がある場合だけSSH許可ルールを作成します。 |
| `01-foundation-network-ai/terraform.tfvars` | `hub_firewall_private_ip` | UDRを有効化する前にHub Azure FirewallのPrivate IPを設定してください。 |
| `02-app/terraform.tfvars` | `acr_name` | アプリ段階で使うACR名です。Azure全体で一意にする必要があります。 |

## 第1段階の設定

管理VMは第1段階で作成しますが、Public IPは付けません。NICには `snet-admin` 内の固定Private IPを割り当てます。

```hcl
create_admin_vm          = true
admin_private_ip_address = "10.30.1.132"
admin_ssh_public_key     = "<SSH公開鍵>"
```

Azure AI Services、Storage Account、Key Vaultは閉域確認向けにPrivate Only設定にします。

```hcl
enable_ai_private_only_access        = true
enable_storage_private_only_access   = true
enable_key_vault_private_only_access = true
```

PoCではAzure Cloud ShellからTerraformを通すため、Storage AccountのShared Key認証を一時的に許可しています。これはPublic Network Accessを開ける設定ではありません。

```hcl
storage_shared_access_key_enabled = true
```

Blob Containerは第1段階では作成しません。StorageをPrivate Onlyにすると、Cloud Shellからデータプレーン操作が失敗する可能性があるためです。

```hcl
create_blob_container = false
```

## UDRとFirewallの注意点

第1段階ではHub未接続の可能性があるため、UDRは変数だけ用意し、実際のRoute Table作成は無効にしています。

```hcl
enable_udr_to_hub_firewall = false
hub_firewall_private_ip    = "<Hub Firewall Private IP>"
```

後続フェーズでUDRを有効化した場合、Route Tableを関連付けるのは `snet-aca-infra` と `snet-admin` のみです。`snet-private-endpoint` には関連付けません。

UDRでHub Firewallへ向ける場合、Azure Container Appsの基盤通信、Managed Identityのトークン取得、コンテナイメージ取得、監視ログ送信のために、Hub Firewall側で限定的な外向き通信許可が必要になる可能性があります。

ネットワーク担当と確認する候補は以下です。

- `mcr.microsoft.com`
- `*.data.mcr.microsoft.com`
- `packages.aks.azure.com`
- `acs-mirror.azureedge.net`
- `login.microsoftonline.com`
- `*.login.microsoftonline.com`
- `*.identity.azure.net`
- `<ACR name>.azurecr.io`
- Azure Monitor / Log Analytics endpoints または AMPLS 設計

業務アプリの通信は、可能な限りPrivate Endpointまたはオンプレミス向け経路を使う想定です。Firewallルール自体は、このSpoke Terraformでは作成しません。

## 実行手順

まず第1段階の基盤を作成します。

```powershell
cd 01-foundation-network-ai
terraform init
terraform fmt
terraform validate
terraform plan -out main.tfplan
terraform apply main.tfplan
```

アプリ段階を実装した後、ACRにイメージを作成し、`02-app` を適用します。

```powershell
az acr build --registry <acr_name> --image ocr-demo-api:v1 ./src/backend
az acr build --registry <acr_name> --image ocr-demo-ui:v1 ./src/ui

cd ../02-app
terraform init
terraform fmt
terraform validate
terraform plan -out main.tfplan
terraform apply main.tfplan
```

## 注意

VNetやSubnetのCIDRを変更すると、既存のAzureリソースがある場合は再作成になる可能性があります。PoC環境を作り直してよい場合は、既存Resource Groupを削除してからfresh applyする方が分かりやすいです。
