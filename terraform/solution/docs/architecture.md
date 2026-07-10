# 第1段階アーキテクチャ

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
      └─ 管理VM（Public IPなし、10.30.0.196）

VNet
└─ Private DNS Zone 5個とVNet Link
   ├─ Azure AI Services + account Private Endpoint
   │  └─ Azure AI Foundry Project
   ├─ Storage Account + blob Private Endpoint
   └─ Key Vault + vault Private Endpoint
```

## Private Endpoint

Private Endpointは、対象リソースのAVMが提供する `private_endpoints` 入力で作成します。

- Azure AI Services: Cognitive Services AVM
- Storage Account Blob: Storage Account AVM
- Key Vault: Key Vault AVM

PE専用AVMやrootの直接resourceを併用せず、Private EndpointとPrivate DNS Zone Groupの二重作成を防ぎます。

## Private DNS Zone

Private DNS Zone AVMを `for_each` で5回呼び出し、各ZoneをSpoke VNetへリンクします。

- `privatelink.cognitiveservices.azure.com`
- `privatelink.openai.azure.com`
- `privatelink.services.ai.azure.com`
- `privatelink.blob.core.windows.net`
- `privatelink.vaultcore.azure.net`

DNS Private ResolverとHub VNetへのDNS Linkは、第2段階のHub共通基盤側で管理します。
