# OCR-Demo 初期基盤用solution root module

更新案件書のフェーズ2「Spoke土台」を、1つのroot module・1つのstateで管理します。細かな自作moduleは作らず、公開済みAzure Verified Modules（AVM）を `main.tf` から直接呼び出します。

## このroot moduleで作成するもの

- Resource Group
- Log Analytics Workspace
- VNetと3つのSubnet
- 管理VM用NSG
- AI系3つ、Blob、Key VaultのPrivate DNS ZoneとVNet Link
- Azure AI ServicesとAzure AI Foundry Project
- Blob用途のStorage AccountとPrivate Endpoint
- Key VaultとPrivate Endpoint
- Public IPなし、固定Private IP、SSH公開鍵認証の管理VM
- Microsoft Entra ID SSH拡張（明示的に有効化した場合だけ）
- Hub Firewall向けUDR（明示的に有効化した場合だけ）
- State Storage用Private Endpoint（管理VM移行後に明示的に有効化した場合だけ）

ACR、Container Apps、DNS Private Resolver、Hub Firewall、Hub-Spoke Peering、Key Vault Secret、アプリ用Blob Containerは作成しません。これらは後続フェーズまたは別管理範囲です。

## ネットワーク

```text
10.30.0.0/24  VNet
├─ 10.30.0.0/25    snet-aca-infra
├─ 10.30.0.128/26  snet-private-endpoint
├─ 10.30.0.192/28  snet-admin
└─ 10.30.0.208-255 将来予約
```

管理VMの固定Private IPは `10.30.0.196` です。Public IPは作成しません。Hub AzureBastionSubnetのCIDRが `null` の場合、管理VM用NSGは作成しますがSSH許可ルールは作成しません。

管理VMにはSystem Assigned Managed Identityを設定します。初期値の `enable_admin_vm_entra_id_login = false` では `AADSSHLoginForLinux` 拡張を導入せず、SSH公開鍵だけを設定します。Hub接続と必要な外向き通信を確認した後にEntra ID SSHを有効化できます。`admin_vm_login_principal_id` を設定した場合は、専用Resource Groupへ `Virtual Machine Administrator Login` を付与します。秘密鍵はTerraformへ入力しません。

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

backendにはStorage Account Keyや接続文字列を保存しません。Cloud Shell用の `backend.hcl` では `use_azuread_auth = true` と `use_cli = true` を使用します。

- Cloud Shell: Azure CLI / Microsoft Entra ID認証
- 管理VM: Managed IdentityまたはAzure CLI / Microsoft Entra ID認証

アプリ用Storage AccountはMicrosoft Entra ID認証を既定とし、Shared Keyを無効にします。採用しているStorage AVMはAzAPIとEntra IDで管理するため、Blob Container等のデータプレーンresourceを作らない初期基盤ではShared Keyを必要としません。

AI Services、アプリ用Storage Account、Key VaultのPublic Network Accessはコードで常に無効化し、Network Ruleの既定アクションを `Deny` に固定しています。tfvars側で公開設定を切り替える二重指定は設けていません。

## State StorageのPrivate化

初期Cloud Shell構築ではState StorageのPublic Network Accessを維持し、`enable_state_storage_private_endpoint = false` とします。管理VMからAzure Storage backendへ到達できる経路と名前解決を準備した後、bootstrap outputのStorage Account IDと名前をsolutionへ設定し、State StorageのBlob Private Endpointを作成できます。

```hcl
enable_state_storage_private_endpoint = true
state_storage_account_id              = "/subscriptions/.../providers/Microsoft.Storage/storageAccounts/..."
state_storage_account_name            = "<tfstate-storage-account-name>"
```

Private Endpointの作成と管理VMからのbackend疎通を確認してから、bootstrap側の `state_public_network_access_enabled = false`、`state_network_default_action = "Deny"` へ切り替えます。標準Cloud Shellから実行している間に先にPublic Network Accessを無効化しないでください。

## 管理VMの初期接続と外向き通信

初期値ではSSH公開鍵認証を使用します。Hub Azure Bastion等の承認済み経路から接続するには、次の前提が必要です。

- Hub側などにSpoke管理VMへ到達可能なAzure Bastionがあること
- `hub_azure_bastion_subnet_prefix` 設定時だけTCP/22許可ルールが作成されること
- `admin_ssh_public_key` に公開鍵だけを設定し、秘密鍵をGitやTerraformへ入れないこと

Microsoft Entra ID SSHへ切り替える場合は、AADSSHLoginForLinuxの導入に必要な送信経路と、接続者の `Virtual Machine Administrator Login` または `Virtual Machine User Login` を準備します。

2026年3月31日以降のAPIで作成する新規VNetは、SubnetがPrivateを既定とする場合があります。Public IPは追加せず、Hub Firewall等の明示的な外向き経路と、`packages.microsoft.com`、Microsoft Entra ID、Azure Instance Metadata Service等への必要最小限の通信をネットワーク担当と確認してください。Hub未接続で必要な送信経路がない場合、AADSSHLoginForLinux拡張の導入は失敗する可能性があります。

## UDRとHub Firewall

初期基盤では `enable_udr_to_hub_firewall = false` とします。有効化した場合、Route Tableを関連付けるのはACA用Subnetと管理VM用Subnetだけです。Private Endpoint用Subnetには関連付けません。

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
- [`docs/latest-handover-compliance.md`](docs/latest-handover-compliance.md): 更新案件書との最新照合結果
- [`docs/application-boundary.md`](docs/application-boundary.md): StreamlitモックとAzure基盤の責任分界
- [`docs/requirements-v2.0-compliance.md`](docs/requirements-v2.0-compliance.md): 以前の案件書v2.0との照合履歴
- [`docs/beginner-guide.md`](docs/beginner-guide.md): 初心者向けのTerraform・Azure基礎解説
- [`docs/phase-roadmap.md`](docs/phase-roadmap.md): フェーズごとの実装範囲
