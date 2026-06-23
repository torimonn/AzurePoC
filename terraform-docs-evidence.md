# Terraform 公式ドキュメント エビデンス

取得日: 2026-06-08

このファイルは、本リポジトリの Terraform コードで使っている主要リソースについて、公式ドキュメント上の根拠を整理したものです。

参照元は主に HashiCorp の `terraform-provider-azurerm` 公式ドキュメントです。Terraform Registry はブラウザ上では JavaScript 表示のため、保存用エビデンスでは HashiCorp 公式 GitHub リポジトリ内の同一ドキュメント Markdown を併記しています。

## 対象コード

- `01-foundation-network-ai/main.tf`
- `01-foundation-network-ai/variables.tf`
- `01-foundation-network-ai/terraform.tfvars`
- `02-app/main.tf`
- `02-app/variables.tf`
- `02-app/terraform.tfvars`

## 01-foundation-network-ai

| Terraform リソース | コード上の用途 | 公式ドキュメント | 根拠メモ |
|---|---|---|---|
| `azurerm_resource_group` | OCR Demo 用リソースをまとめる Resource Group | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/resource_group.html.markdown | Resource Group を管理するリソース。`name`, `location`, `tags` を指定できる。 |
| `azurerm_virtual_network` | Azure 内の仮想ネットワーク | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/virtual_network.html.markdown | VNet を管理するリソース。公式ドキュメントでは、VNet 内インライン Subnet と単独 `azurerm_subnet` の併用は競合すると説明されているため、本コードでは単独 `azurerm_subnet` に統一している。 |
| `azurerm_subnet` | Container Apps 用サブネット、Private Endpoint 用サブネット | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/subnet.html.markdown | Subnet を管理するリソース。`delegation` と `service_delegation` を使って `Microsoft.App/environments` へ委任できる。 |
| `azurerm_log_analytics_workspace` | Container Apps のログ出力先 | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/log_analytics_workspace.html.markdown | Log Analytics Workspace を管理するリソース。`sku = "PerGB2018"` と `retention_in_days = 30` は公式 Example Usage と同じ基本形。 |
| `azurerm_cognitive_account` | Azure AI Foundry / AI Services アカウント | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/cognitive_account.html.markdown | Cognitive Services Account を管理するリソース。`kind = "AIServices"` は Azure AI Foundry 系の用途として記載あり。`network_acls` 指定時は `custom_subdomain_name` が必要。 |
| `azurerm_cognitive_account_project` | Azure AI Foundry Project | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account_project / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/cognitive_account_project.html.markdown | Cognitive Account Project を管理するリソース。親 Cognitive Account 側に `project_management_enabled = true`, `kind = "AIServices"`, Managed Identity, `custom_subdomain_name` が必要。 |
| `azurerm_private_dns_zone` | Private Endpoint 用 DNS Zone | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/private_dns_zone.html.markdown | Private DNS Zone を管理するリソース。Private Endpoint と使う場合はサービスに対応した Private DNS Zone 名が必要。 |
| `azurerm_private_dns_zone_virtual_network_link` | Private DNS Zone と VNet のリンク | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/private_dns_zone_virtual_network_link.html.markdown | Private DNS Zone を VNet にリンクし、VNet 内で名前解決できるようにするリソース。 |
| `azurerm_private_endpoint` | Azure AI Services への Private Endpoint | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/private_endpoint.html.markdown | Private Endpoint を管理するリソース。`private_service_connection`, `private_connection_resource_id`, `subresource_names`, `private_dns_zone_group` を使う構成が公式例にある。 |
| `azurerm_storage_account` | OCR対象ファイルや結果JSON用 Blob Storage | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/storage_account.html.markdown | Storage Account を管理するリソース。`StorageV2`, `public_network_access_enabled`, `allow_nested_items_to_be_public`, `shared_access_key_enabled`, `network_rules` を使う。 |
| `azurerm_storage_container` | 将来用 Blob Container optional 作成 | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/storage_container.html.markdown | Container は初期状態では作成しない。作成する場合は `create_blob_container = true` のときだけ作成し、現在推奨される `storage_account_id` を使用する。 |
| `azurerm_key_vault` | アプリ用シークレットや証明書の閉域管理基盤 | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/key_vault.html.markdown | Key Vault を管理するリソース。`enable_rbac_authorization = true`, `public_network_access_enabled`, `network_acls`, `soft_delete_retention_days`, `purge_protection_enabled` を使う。 |
| `azurerm_route_table` | Hub Firewall 向けUDR用 Route Table | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table | 第1段階では `enable_udr_to_hub_firewall = false` のため作成しない。Hub接続後に有効化する。 |
| `azurerm_route` | Default route を Hub Firewall に向けるUDR | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route | `next_hop_type = "VirtualAppliance"` と Hub Firewall Private IP を使う。 |
| `azurerm_subnet_route_table_association` | ACA/Admin Subnet と Route Table の関連付け | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/subnet_route_table_association.html.markdown | Route Tableを関連付けるのは `snet-aca-infra` と `snet-admin` のみ。Private Endpoint Subnetには関連付けない。 |
| `azurerm_network_security_group` | 管理VM用 NSG | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/network_security_group.html.markdown | 管理VMに対する SSH 許可元を Hub 側 `AzureBastionSubnet` のCIDRに限定するために使用。 |
| `azurerm_network_security_rule` | Hub Bastion から管理VMへのSSH許可 | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/network_security_rule.html.markdown | NSG本体にインラインルールを書かず、Hub Bastion CIDRが入った場合だけ作成する。 |
| `azurerm_subnet_network_security_group_association` | `snet-admin` と NSG の関連付け | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/subnet_network_security_group_association.html.markdown | Subnet に NSG を関連付けるために使用。 |
| `azurerm_network_interface` | 管理VM用 NIC | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/network_interface.html.markdown | 管理VMを `snet-admin` に静的 Private IP で配置するために使用。Public IP は付けない。 |
| `azurerm_linux_virtual_machine` | 閉域確認用 管理VM | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/linux_virtual_machine.html.markdown | VNet 内から Private Endpoint / Private DNS の疎通確認を行う任意リソースとして使用。 |

## 02-app

| Terraform リソース | コード上の用途 | 公式ドキュメント | 根拠メモ |
|---|---|---|---|
| `terraform_remote_state` | 01 の出力値を 02 で参照 | https://developer.hashicorp.com/terraform/language/state/remote-state-data | 別 Terraform 構成の root module outputs を取得する組み込み data source。今回の 2段構成で `resource_group_name`, `aca_infra_subnet_id`, `ai_account_id` などを受け渡すために使用。 |
| `azurerm_container_registry` | API/UI Docker イメージ置き場 | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/container_registry.html.markdown | ACR を管理するリソース。`name`, `resource_group_name`, `location`, `sku`, `admin_enabled` を指定できる。`login_server` が出力属性として使える。 |
| `azurerm_user_assigned_identity` | Container Apps が使う Managed Identity | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/user_assigned_identity.html.markdown | User Assigned Identity を管理するリソース。`client_id` と `principal_id` が出力属性として利用できる。 |
| `azurerm_role_assignment` | Managed Identity に ACR / AI 権限を付与 | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/role_assignment.html.markdown | 指定 Principal に指定 Role を指定 Scope で割り当てるリソース。`scope`, `role_definition_name`, `principal_id`, `principal_type` を使用。 |
| `azurerm_container_app_environment` | Container Apps の実行環境 | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/container_app_environment.html.markdown | Container App Environment を管理するリソース。`log_analytics_workspace_id` と `infrastructure_subnet_id` を指定できる。公式ドキュメントでは `infrastructure_subnet_id` 使用時、サブネットは `/21` 以上が必要とされている。 |
| `azurerm_container_app` | API / UI Container App | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app / https://raw.githubusercontent.com/hashicorp/terraform-provider-azurerm/main/website/docs/r/container_app.html.markdown | Container App を管理するリソース。`container_app_environment_id`, `revision_mode`, `identity`, `registry`, `ingress`, `template.container`, `env`, `image`, `cpu`, `memory` を使用。 |

## ドキュメント確認で反映した修正

### Container Apps 用サブネットを `/23` から `/21` へ変更

`azurerm_container_app_environment` の公式ドキュメントでは、`infrastructure_subnet_id` を指定する場合、Subnet は `/21` 以上が必要と記載されている。

そのため、以下を修正した。

- `01-foundation-network-ai/variables.tf`
  - `snet_aca_infra_prefixes` default: `["10.30.0.0/23"]` -> `["10.30.0.0/21"]`
  - `snet_private_endpoint_prefixes` default: `["10.30.2.0/24"]` -> `["10.30.8.0/24"]`
- `01-foundation-network-ai/terraform.tfvars`
  - `snet_aca_infra_prefixes = ["10.30.0.0/21"]`
  - `snet_private_endpoint_prefixes = ["10.30.8.0/24"]`

Private Endpoint 用サブネットも、`10.30.0.0/21` と重複しないように `10.30.8.0/24` へ移動した。

### Phase 1 閉域構築の修正

2026-06-09 に、閉域確認用の第1段階構成として以下を反映した。

1. Provider source は `hashicorp/azurerm` を維持。
2. AI Private DNS Zone を以下の3つに変更。
   - `privatelink.cognitiveservices.azure.com`
   - `privatelink.openai.azure.com`
   - `privatelink.services.ai.azure.com`
3. AI Private Endpoint の `private_dns_zone_group.private_dns_zone_ids` に上記3 Zone をすべて設定。
4. `enable_ai_private_only_access` を追加し、`true` の場合は `public_network_access_enabled = false`, `network_acls.default_action = "Deny"` になるようにした。
5. 第1段階に管理VMを含められるよう、任意作成の `snet-admin`, NSG, NIC, Linux VM を追加した。管理VMには Public IP を付けず、静的 Private IP のみを割り当てる。

管理VMは `create_admin_vm = false` が初期値。利用する場合は `true` に変更し、`admin_ssh_public_key`, `admin_private_ip_address`, `hub_azure_bastion_subnet_prefix` を設定する。

### Blob Storage / Key Vault の閉域PaaS追加

2026-06-11 に、第1フェーズの閉域PaaS基盤として以下を追加した。

1. Blob Storage
   - `azurerm_storage_account.blob`
   - `privatelink.blob.core.windows.net`
   - Blob用 Private Endpoint
   - Blob用 Private DNS Zone VNet Link
   - Blob用 Private DNS Zone Group
2. Blob Container
   - デフォルトでは作成しない。
   - `create_blob_container = true` の場合のみ `azurerm_storage_container.documents` を作成する。
   - 現在の azurerm ドキュメントに合わせ、`storage_account_name` ではなく `storage_account_id` を使う。
3. Key Vault
   - `azurerm_key_vault.this`
   - `enable_rbac_authorization = true`
   - Secret は第1フェーズでは作成しない。
   - `privatelink.vaultcore.azure.net`
   - Key Vault用 Private Endpoint
   - Key Vault用 Private DNS Zone VNet Link
   - Key Vault用 Private DNS Zone Group
4. 閉域切替
   - `enable_storage_private_only_access = true` の場合、Storage は `public_network_access_enabled = false`, `network_rules.default_action = "Deny"`。
   - `enable_key_vault_private_only_access = true` の場合、Key Vault は `public_network_access_enabled = false`, `network_acls.default_action = "Deny"`。

Azure AI Search、Key Vault Secret、Storage/Key Vault向けアプリ用Role Assignment、Container Apps、ACRは追加していない。

### VNet / UDR / 管理VM SSHルールの調整

2026-06-23 に、GitHub `torimonn/AzurePoC` とローカルのTerraform 5ファイルが一致していることを確認したうえで、追加要件として以下を反映した。

1. VNet全体を `10.30.0.0/22` に縮小。
2. Subnet は `snet-aca-infra = 10.30.0.0/23`, `snet-private-endpoint = 10.30.2.0/24`, `snet-admin = 10.30.3.0/27` を維持。
3. Private Endpoint Subnet に `private_endpoint_network_policies = "Disabled"` を明示。
4. UDR用に `enable_udr_to_hub_firewall` と `hub_firewall_private_ip` を追加。
5. `enable_udr_to_hub_firewall = true` の場合のみ Route Table / Default route / ACA Subnet association / Admin Subnet association を作成。
6. Private Endpoint SubnetにはRoute Tableを関連付けない。
7. 管理VM用NSGからインライン `security_rule` を削除し、`azurerm_network_security_rule.admin_ssh_from_hub_bastion` に分離。
8. `hub_azure_bastion_subnet_prefix = null` の場合、SSH許可ルールは作成しない。
9. `hub_azure_bastion_subnet_prefix` を必須にするpreconditionは削除し、SSH公開鍵のpreconditionのみ維持。

## 注意点

1. `terraform_remote_state` は便利だが、HashiCorp ドキュメントでは state snapshot 全体へのアクセス権が必要になる点に注意するよう説明されている。本番では Azure Storage Account backend や Key Vault / App Configuration / DNS など、より明示的な値の受け渡し方式も検討する。
2. `02-app/terraform.tfvars` の `acr_name` はまだ仮値 `acrocrdemodevxxxxx` なので、実行前に Azure 全体で一意な名前へ変更する。
3. AI Services は `enable_ai_private_only_access = true` の場合、閉域確認向けに `false` / `Deny` へ切り替わる。Portal 操作や切り分けで一時的に公開許可したい場合は `enable_ai_private_only_access = false` にする。
