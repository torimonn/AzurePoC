# solution root module

OCR-Demo第1段階のAzure基盤を、1つのroot module・1つのstateで管理します。細かな自作moduleは作らず、公開済みAzure Verified Modules（AVM）を `main.tf` から直接呼び出します。

## 第1段階で作成するもの

- Resource Group
- Log Analytics Workspace
- VNetと3つのSubnet
- 管理VM用NSG
- AI系3つ、Blob、Key VaultのPrivate DNS ZoneとVNet Link
- Azure AI ServicesとAzure AI Foundry Project
- Blob用途のStorage AccountとPrivate Endpoint
- Key VaultとPrivate Endpoint
- Public IPなし、固定Private IP、Microsoft Entra ID SSH対応の管理VM
- Hub Firewall向けUDR（明示的に有効化した場合だけ）
- State Storage用Private Endpoint（管理VM移行後に明示的に有効化した場合だけ）

ACR、Container Apps、DNS Private Resolver、Hub Firewall、Hub-Spoke Peering、Key Vault Secret、アプリ用Blob Containerは作成しません。

## ネットワーク

```text
10.30.0.0/24  VNet
├─ 10.30.0.0/25    snet-aca-infra
├─ 10.30.0.128/26  snet-private-endpoint
├─ 10.30.0.192/28  snet-admin
└─ 10.30.0.208～10.30.0.255  未使用
```

管理VMの固定Private IPは `10.30.0.196` です。Public IPは作成しません。Hub AzureBastionSubnetのCIDRが `null` の場合、管理VM用NSGは作成しますがSSH許可ルールは作成しません。

管理VMにはSystem Assigned Managed Identityと `AADSSHLoginForLinux` 拡張を設定します。`admin_vm_login_principal_id` を設定した場合は、専用Resource Groupへ `Virtual Machine Administrator Login` を付与します。`null` の場合は拡張だけを導入し、Role Assignmentは共通基盤側などで別途実施します。SSH公開鍵はbreak-glass用として維持し、秘密鍵はTerraformへ入力しません。

ACA用Subnetには `Microsoft.App/environments` delegationを設定します。Private Endpoint用SubnetではPrivate Endpoint network policiesを無効化します。

## 初期化とplan

`bootstrap`でAzure Storage backendを作成した後、exampleを参考にGit管理しない `terraform.tfvars` と `backend.hcl` を用意します。

```bash
terraform fmt -recursive
terraform init -reconfigure -backend-config=backend.hcl
terraform validate
terraform plan -out=ocr-demo.tfplan
terraform show -no-color ocr-demo.tfplan > plan.txt
terraform providers
```

通常の確認では `terraform init -upgrade` を実行しません。AVMまたはProviderを更新するときだけ、変更内容と破壊的変更を確認した上で明示的に実行します。

## 認証

backendにはStorage Account Keyや接続文字列を保存しません。`backend.hcl` の `use_azuread_auth = true` を使用します。

- Cloud Shell: Azure CLI / Microsoft Entra ID認証
- 管理VM: Managed IdentityまたはAzure CLI / Microsoft Entra ID認証

アプリ用Storage AccountのShared Keyは、Cloud Shellからの第1段階PoC作業を考慮して一時的に有効化しています。Public Network Accessは無効のままです。本番運用ではManaged IdentityとRBACを優先し、Shared Key無効化を検討します。

## State StorageのPrivate化

初期Cloud Shell構築ではState StorageのPublic Network Accessを維持し、`enable_state_storage_private_endpoint = false` とします。管理VMからAzure Storage backendへ到達できる経路と名前解決を準備した後、bootstrap outputのStorage Account IDと名前をsolutionへ設定し、State StorageのBlob Private Endpointを作成できます。

```hcl
enable_state_storage_private_endpoint = true
state_storage_account_id              = "/subscriptions/.../providers/Microsoft.Storage/storageAccounts/..."
state_storage_account_name            = "<tfstate-storage-account-name>"
```

Private Endpointの作成と管理VMからのbackend疎通を確認してから、bootstrap側の `state_public_network_access_enabled = false`、`state_network_default_action = "Deny"` へ切り替えます。標準Cloud Shellから実行している間に先にPublic Network Accessを無効化しないでください。

## 管理VMの初期接続と外向き通信

Azure BastionとMicrosoft Entra IDで接続するには、次の前提が必要です。

- Hub側などにSpoke管理VMへ到達可能なAzure Bastionがあること
- `hub_azure_bastion_subnet_prefix` 設定時だけTCP/22許可ルールが作成されること
- AADSSHLoginForLinuxの導入に必要な送信経路があること
- 接続者に `Virtual Machine Administrator Login` または `Virtual Machine User Login` が付与されていること

2026年3月31日以降のAPIで作成する新規VNetは、SubnetがPrivateを既定とする場合があります。Public IPは追加せず、Hub Firewall等の明示的な外向き経路と、`packages.microsoft.com`、Microsoft Entra ID、Azure Instance Metadata Service等への必要最小限の通信をネットワーク担当と確認してください。Hub未接続で必要な送信経路がない場合、AADSSHLoginForLinux拡張の導入は失敗する可能性があります。

## UDRとHub Firewall

第1段階では `enable_udr_to_hub_firewall = false` とします。有効化した場合、Route Tableを関連付けるのはACA用Subnetと管理VM用Subnetだけです。Private Endpoint用Subnetには関連付けません。

Hub FirewallへUDRを向ける場合、Azure Container Appsの基盤依存、Managed Identityのトークン取得、コンテナイメージ取得、監視ログ送信のため、限定的な外向き通信許可が必要になる可能性があります。ネットワーク担当と次の候補を確認してください。

- `mcr.microsoft.com`
- `*.data.mcr.microsoft.com`
- `packages.aks.azure.com`
- `acs-mirror.azureedge.net`
- `login.microsoftonline.com`
- `*.login.microsoftonline.com`
- `*.identity.azure.net`
- `<ACR name>.azurecr.io`
- Azure Monitor / Log Analytics endpoint、またはAMPLS設計

業務アプリ通信は、可能な限りPrivate Endpointまたはオンプレミス向け経路を使用します。Hub Firewallのルール自体はこのTerraformでは作成しません。

## AVM telemetry

AVM telemetryは、組織・セキュリティレビューが完了するまで一時的に無効化しています。すべてのAVM呼び出しで `enable_telemetry = false` を指定しています。

## 関連資料

- [`docs/architecture.md`](docs/architecture.md): 構成と依存関係
- [`docs/avm-module-selection.md`](docs/avm-module-selection.md): AVM固定バージョンとProvider依存
- [`docs/state-migration.md`](docs/state-migration.md): 旧resourceからAVMへのstate移行
- [`docs/offline-deployment.md`](docs/offline-deployment.md): 閉域管理VMへの持ち込み
- [`docs/requirements-v1.1-compliance.md`](docs/requirements-v1.1-compliance.md): 要件整理書v1.1との照合結果
