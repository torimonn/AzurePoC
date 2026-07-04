# OCR Demo Terraform

Azure OCR-Demo PoC 用のTerraformコードです。第1段階では、Spoke側の閉域Azure基盤を作成します。第3段階でACR、Container Apps、Managed Identityを追加しやすいように、root moduleは全体の組み立てに寄せ、実リソースは `modules/` 配下へ用途別に分割しています。

## ディレクトリ構成

```text
01-foundation-network-ai/
├─ terraform.tf
├─ providers.tf
├─ main.tf
├─ variables.tf
├─ outputs.tf
├─ terraform.tfvars
├─ terraform.tfvars.example
├─ .gitignore
└─ modules/
   ├─ network/
   ├─ private_dns/
   ├─ ai_foundry/
   ├─ storage/
   ├─ key_vault/
   ├─ log_analytics/
   ├─ admin_vm/
   └─ udr/
```

## 第1段階で作成するもの

- Resource Group
- VNet / Subnet
- Private DNS Zone / VNet Link
- Private Endpoint
- Azure AI Services
- Azure AI Foundry Project
- Blob Storage用Storage Account
- Key Vault
- Log Analytics Workspace
- Public IPなしの管理VM
- UDR用変数とUDRリソース定義

UDRは第1段階では無効です。

```hcl
enable_udr_to_hub_firewall = false
```

ACR、Container Apps Environment、Container App、アプリ用Managed Identity、Role Assignmentは第1段階では作成しません。第3段階で追加する想定です。

## ネットワーク設計

VNetは小規模PoC向けに `/24` へ縮小しています。

```text
VNet:
  10.30.0.0/24

ACA用Subnet:
  10.30.0.0/25

Private Endpoint用Subnet:
  10.30.0.128/26

管理VM用Subnet:
  10.30.0.192/28

管理VM Private IP:
  10.30.0.196

予備:
  10.30.0.208 - 10.30.0.255
```

このVNetは小規模PoC向けに意図的にコンパクトにしています。将来、複数のContainer Apps Environment、Application Gateway、AKS、Spoke側Azure DNS Private Resolver、追加の委任Subnetが必要になる場合は、VNetアドレス空間の再検討が必要です。

## moduleの役割

| module | 役割 |
|---|---|
| `network` | VNet、ACA用Subnet、Private Endpoint用Subnet、管理VM用Subnetを作成します。 |
| `private_dns` | AI系3つ、Blob用、Key Vault用のPrivate DNS ZoneとVNet Linkを作成します。 |
| `ai_foundry` | Azure AI Services、AI Project、AI用Private Endpointを作成します。 |
| `storage` | Storage Account、Blob用Private Endpoint、任意のBlob Containerを作成します。 |
| `key_vault` | Key Vault、Key Vault用Private Endpointを作成します。 |
| `log_analytics` | Log Analytics Workspaceを作成します。 |
| `admin_vm` | 管理VM用NSG、任意のSSH許可ルール、NIC、Linux VMを作成します。 |
| `udr` | Hub Firewall向けRoute Table、Default Route、Subnet関連付けを定義します。第1段階では無効です。 |

root `main.tf` は、Resource Groupの作成とmodule呼び出しを中心にしています。module間の値の受け渡しはoutput経由です。

## 管理VMアクセス方針

管理VMは第1段階で作成しますが、Public IPは付けません。

```hcl
create_admin_vm          = true
admin_private_ip_address = "10.30.0.196"
```

`admin_ssh_public_key` は内部の緊急復旧用SSH公開鍵として扱います。通常の外部ベンダー接続は、後続フェーズでBastion経由のMicrosoft Entra ID認証へ寄せる想定です。

```hcl
admin_ssh_public_key = "<internal-break-glass-ssh-public-key>"
```

`hub_azure_bastion_subnet_prefix` は任意です。`null` の場合、管理VM用NSGは作成しますが、SSH許可ルールは作成しません。

```hcl
hub_azure_bastion_subnet_prefix = null
```

## Private DNS / Private Endpoint方針

Azure AI系Private DNS Zoneは3つ維持します。

```text
privatelink.cognitiveservices.azure.com
privatelink.openai.azure.com
privatelink.services.ai.azure.com
```

Blob用とKey Vault用も作成します。

```text
privatelink.blob.core.windows.net
privatelink.vaultcore.azure.net
```

Private Endpoint用Subnetには `private_endpoint_network_policies = "Disabled"` を明示しています。

## Storage / Key Vault方針

Cloud ShellからのPoC applyを考慮し、Storage Accountは一時的にShared Key認証を許可しています。これはPublic Network Accessを開ける設定ではありません。

```hcl
storage_shared_access_key_enabled = true
```

本番寄せでは、Managed Identity / RBAC中心に寄せ、Shared Key無効化を検討します。

Blob Containerは第1段階では作成しません。

```hcl
create_blob_container = false
```

Key Vault Secretも第1段階ではTerraformで作成しません。Secret値がTerraform stateに残る可能性があるためです。

## UDR / Firewall注意事項

UDRは第1段階では無効です。後続フェーズでHub接続後に有効化します。

```hcl
hub_firewall_private_ip    = "<Hub Firewall Private IP>"
enable_udr_to_hub_firewall = false
```

UDRを有効化しても、Route Tableを関連付けるのは `snet-aca-infra` と `snet-admin` のみです。`snet-private-endpoint` には関連付けません。

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

## 第3段階で追加予定の構成

第3段階では、以下を追加する想定です。

- Azure Container Registry Premium
- ACR Private Endpoint
- Private DNS Zone: `privatelink.azurecr.io`
- Container Apps Environment
- API Container App
- UI Container App
- User Assigned Managed Identity
- `AcrPull`、Storage Blob Data Contributor、Key Vault Secrets User などのRole Assignment

ACRのPublic Accessを無効にする場合、イメージのbuild/pushは管理VMまたはSelf-hosted runnerから行う設計を検討します。

## Azure Verified Modulesについて

今回はAzure Verified Modulesを全面採用せず、既存コードをローカルmoduleへ整理しています。将来AVMへ寄せる場合の候補は以下です。

- `Azure/avm-res-network-virtualnetwork/azure`
- `Azure/avm-res-network-privateendpoint/azure`
- `Azure/avm-res-network-routetable/azure`
- `Azure/avm-res-keyvault-vault/azure`
- `Azure/avm-res-storage-storageaccount/azure`
- `Azure/avm-res-operationalinsights-workspace/azure`
- `Azure/avm-res-containerregistry-registry/azure`
- `Azure/avm-res-app-managedenvironment/azure`
- `Azure/avm-res-app-containerapp/azure`
- `Azure/avm-res-cognitiveservices-account/azure`

AVMで一般的な `tags`、`role_assignments`、`diagnostic_settings`、`lock`、`managed_identities`、`private_endpoints` などの設計考え方は、今後の拡張時に参考にします。AVM moduleの `enable_telemetry` は、閉域・監査環境ではレビュー対象になるため、将来検討事項として扱います。

## state移行の注意

すでに `terraform apply` 済みのstateがある状態でroot直書きからmodule構成へ移すと、Terraform上のリソースアドレスが変わります。

例:

```text
azurerm_virtual_network.this
```

から

```text
module.network.azurerm_virtual_network.this
```

へ変わります。

既存環境を残す場合は、`moved` blockまたは `terraform state mv` が必要になる可能性があります。PoCでResource Groupを削除済み、またはfresh apply前であれば、新規stateとして扱えます。

## 実行手順

```powershell
cd 01-foundation-network-ai
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

この環境で初回applyする前に、`terraform.tfvars` の以下を実値へ置き換えてください。

- `admin_ssh_public_key`
- `hub_firewall_private_ip`
- 必要に応じて `subscription_id`
- 必要に応じて `hub_azure_bastion_subnet_prefix`
