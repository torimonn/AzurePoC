# Terraform公式ドキュメント確認メモ

取得日: 2026-06-24

このファイルは、OCR-DemoのTerraformコードで使っている主要リソースについて、公式ドキュメント上の確認結果を整理したものです。

## 確認したTerraform Providerリソース

Terraform Registryはブラウザ上でJavaScript表示になるため、証跡としてHashiCorp公式の `terraform-provider-azurerm` リポジトリ内Markdownも参照対象にしています。

| 区分 | Terraformリソース | 公式ドキュメント |
|---|---|---|
| Provider | `hashicorp/azurerm` | https://registry.terraform.io/providers/hashicorp/azurerm/latest |
| VNet | `azurerm_virtual_network` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network |
| Subnet | `azurerm_subnet` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet |
| Private DNS Zone | `azurerm_private_dns_zone` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone |
| Private DNS VNet Link | `azurerm_private_dns_zone_virtual_network_link` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link |
| Private Endpoint | `azurerm_private_endpoint` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint |
| Azure AI Services | `azurerm_cognitive_account` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account |
| Azure AI Foundry Project | `azurerm_cognitive_account_project` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account_project |
| Storage Account | `azurerm_storage_account` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account |
| Blob Container | `azurerm_storage_container` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container |
| Key Vault | `azurerm_key_vault` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault |
| Route Table | `azurerm_route_table` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table |
| Route | `azurerm_route` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route |
| Route Table Association | `azurerm_subnet_route_table_association` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association |
| NSG | `azurerm_network_security_group` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group |
| NSG Rule | `azurerm_network_security_rule` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule |
| NIC | `azurerm_network_interface` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface |
| Linux VM | `azurerm_linux_virtual_machine` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine |

## 現在の第1段階ネットワーク設計

第1段階の基盤は、IPを節約するため以下の `/23` VNet構成にしています。

```text
VNet全体:                  10.30.0.0/23
ACA用Subnet:               10.30.0.0/24
Private Endpoint用Subnet:  10.30.1.0/25
管理VM用Subnet:            10.30.1.128/28
管理VMのPrivate IP:        10.30.1.132
予備:                      10.30.1.144 - 10.30.1.255
```

ACA用Subnetは、将来のAzure Container Apps Workload profiles環境を想定しています。Microsoft Learnでは、Workload profiles環境はUDRをサポートし、最小Subnetサイズは `/27` とされています。一方、従来のConsumption only環境は `/23` が必要で、UDRをサポートしません。

## 実装メモ

- Private Endpoint用Subnetでは、`private_endpoint_network_policies = "Disabled"` を明示しています。
- Azure AI系のPrivate DNS Zoneは以下3つを維持しています。
  - `privatelink.cognitiveservices.azure.com`
  - `privatelink.openai.azure.com`
  - `privatelink.services.ai.azure.com`
- Blob用とKey Vault用のPrivate DNS Zoneも作成します。
  - `privatelink.blob.core.windows.net`
  - `privatelink.vaultcore.azure.net`
- Key Vaultは `rbac_authorization_enabled = true` を使い、Access Policy方式ではなくAzure RBAC方式にしています。
- Storage Accountは、Cloud ShellからのPoC実行を通すため `shared_access_key_enabled = true` を維持しています。ただしPublic Network Accessは別設定で閉じます。
- Blob Containerは `create_blob_container = false` を既定にしています。Private Only Storageでは、Cloud Shellからのデータプレーン操作が失敗する可能性があるためです。
- 第1段階ではKey Vault Secretを作成しません。Secret値をTerraform stateに残さないためです。
- 管理VMは閉域確認用で、Public IPなしの構成です。
  - NICはPrivate IPのみです。
  - Private IPは固定です。
  - SSH許可ルールは `hub_azure_bastion_subnet_prefix` に値がある場合だけ作成します。
- UDRリソースは `enable_udr_to_hub_firewall = true` の場合だけ作成します。
- Route Tableを関連付ける対象は、ACA用Subnetと管理VM用Subnetだけです。Private Endpoint用Subnetには関連付けません。
- Azure DNS Private ResolverはこのSpoke Terraformでは作成しません。Hub側共通基盤で扱う想定です。

## Firewallと外向き通信の注意点

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
