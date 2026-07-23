# OCR-Demo 初期基盤アーキテクチャ

## root moduleの依存関係

```text
Resource Group
├─ Log Analytics Workspace
├─ 管理VM用NSG
├─ Route Table（UDR有効時のみ）
└─ VNet
   ├─ ACA用Subnet（NSGなし、UDRは有効時のみ）
   ├─ Private Endpoint用Subnet（UDRなし）
   └─ 管理VM用Subnet（NSG、UDRは有効時のみ）
      └─ 管理VM（Public IPなし、10.30.0.196、初期はSSH公開鍵認証）

VNet
└─ Private DNS Zone 5個とVNet Link
   ├─ Azure AI Services + account Private Endpoint
   │  └─ Azure AI Foundry Project
   ├─ アプリ用Storage Account + blob Private Endpoint
   ├─ State Storage + blob Private Endpoint（管理VM移行後、任意）
   └─ Key Vault + vault Private Endpoint
```

## Private Endpoint

Private Endpointは、対象リソースのAVMが提供する `private_endpoints` 入力で作成します。

- Azure AI Services: Cognitive Services AVM
- Storage Account Blob: Storage Account AVM
- Key Vault: Key Vault AVM
- State Storage: Private Endpoint AVM（管理VM移行後に有効化）

アプリ側3サービスでは各リソースAVMのPrivate Endpoint機能を使い、rootの直接resourceとは併用しません。State Storageはbootstrap側の既存Storage Accountを参照するため、PE専用AVMをsolutionから1回だけ呼び出し、Private EndpointとPrivate DNS Zone Groupの二重作成を防ぎます。

## Private DNS Zone

Private DNS Zone AVMを `for_each` で5回呼び出し、各ZoneをSpoke VNetへリンクします。

- `privatelink.cognitiveservices.azure.com`
- `privatelink.openai.azure.com`
- `privatelink.services.ai.azure.com`
- `privatelink.blob.core.windows.net`
- `privatelink.vaultcore.azure.net`

DNS Private ResolverとHub VNetへのDNS Linkは、Hub接続フェーズの共通基盤側で管理します。

## 管理VMアクセス

管理VMはSystem Assigned Managed Identityを持ちます。初期値ではSSH公開鍵認証だけを使用し、`AADSSHLoginForLinux` 拡張は作成しません。Hub接続と外向き通信を確認して `enable_admin_vm_entra_id_login = true` にした場合だけ拡張を導入します。接続者のObject IDが指定された場合、専用Resource Groupのスコープで `Virtual Machine Administrator Login` を付与します。Azure Bastion、Hub接続、MFA、条件付きアクセス、PIMは共通基盤側の設計対象です。

VMにはPublic IPを作成しません。AADSSHLoginForLinuxの導入やOS更新に必要な外向き通信は、Hub Firewallなどの明示的な送信経路で許可します。
