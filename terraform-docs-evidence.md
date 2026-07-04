# Terraform公式ドキュメント確認メモ

取得日: 2026-07-04

OCR-DemoのTerraformコードで使っている主要リソースについて、公式ドキュメント上の確認結果を整理したものです。

## 確認したTerraform Providerリソース

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

```text
VNet全体:                  10.30.0.0/24
ACA用Subnet:               10.30.0.0/25
Private Endpoint用Subnet:  10.30.0.128/26
管理VM用Subnet:            10.30.0.192/28
管理VMのPrivate IP:        10.30.0.196
予備:                      10.30.0.208 - 10.30.0.255
```

## module構成

root `main.tf` はResource Groupとmodule呼び出しを中心にし、Azureリソース本体は以下へ分割しています。

- `modules/network`
- `modules/private_dns`
- `modules/ai_foundry`
- `modules/storage`
- `modules/key_vault`
- `modules/log_analytics`
- `modules/admin_vm`
- `modules/udr`

## 実装メモ

- Private Endpoint用Subnetでは `private_endpoint_network_policies = "Disabled"` を明示しています。
- Azure AI系Private DNS Zoneは3つ維持しています。
  - `privatelink.cognitiveservices.azure.com`
  - `privatelink.openai.azure.com`
  - `privatelink.services.ai.azure.com`
- Blob用とKey Vault用のPrivate DNS Zoneも作成します。
  - `privatelink.blob.core.windows.net`
  - `privatelink.vaultcore.azure.net`
- Key Vaultは `rbac_authorization_enabled = true` を使い、Access Policy方式ではなくAzure RBAC方式にしています。
- Storage Accountは、Cloud ShellからのPoC実行を通すため `shared_access_key_enabled = true` を維持しています。ただしPublic Network Accessは別設定で閉じます。
- Blob Containerは `create_blob_container = false` を既定にしています。
- 第1段階ではKey Vault Secretを作成しません。
- 管理VMはPublic IPなし、固定Private IPの構成です。
- SSH許可ルールは `hub_azure_bastion_subnet_prefix` に値がある場合だけ作成します。
- UDRリソースは `enable_udr_to_hub_firewall = true` の場合だけ作成します。
- Route Tableを関連付ける対象は、ACA用Subnetと管理VM用Subnetだけです。
- Azure DNS Private ResolverはこのSpoke Terraformでは作成しません。

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
