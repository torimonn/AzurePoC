# AVM選定記録

確認日: 2026-07-18

Terraform Registryの公開済みmodule、各固定版のREADME、Inputs、Outputs、Examples、`terraform.tf` を確認して選定しました。

| 用途 | Module source | Version | 主なProvider制約 | 採用理由・注意点 |
|---|---|---:|---|---|
| Resource Group | `Azure/avm-res-resources-resourcegroup/azurerm` | 0.4.0 | azapi `~>2.4` | Resource GroupをAVMで統一。 |
| Log Analytics | `Azure/avm-res-operationalinsights-workspace/azurerm` | 0.5.1 | azurerm `>=4.36,<5`、azapi `~>2.4` | Workspace ID、Name、Customer IDを利用。Shared Keyは出力しない。 |
| NSG | `Azure/avm-res-network-networksecuritygroup/azurerm` | 0.5.1 | azurerm `~>4.0` | 条件付きSSHルールを `security_rules` mapで作成。 |
| Route Table | `Azure/avm-res-network-routetable/azurerm` | 0.5.0 | azurerm `~>4.0` | UDR有効時だけ呼び出す。PE用Subnetには関連付けない。 |
| VNet・Subnet | `Azure/avm-res-network-virtualnetwork/azurerm` | 0.19.0 | azapi `~>2.4` | Subnet delegation、NSG、Route Table、PE policyを1つの入力で管理。 |
| Private DNS Zone | `Azure/avm-res-network-privatednszone/azurerm` | 0.5.0 | azapi `~>2.4`、time `~>0.13` | 5Zoneを `for_each` で作成し、Spoke VNet Linkも同じmoduleで管理。 |
| Storage Account | `Azure/avm-res-storage-storageaccount/azurerm` | 0.7.3 | azapi `~>2.8` | Blob PEとDNS Zone Groupに対応。子resourceはAzAPIのARM操作で管理。 |
| Private Endpoint | `Azure/avm-res-network-privateendpoint/azurerm` | 0.2.0 | azurerm `>=3.71,<5` | 管理VM移行後のState Storage用PEだけに使用。初期段階は `count = 0`。 |
| Key Vault | `Azure/avm-res-keyvault-vault/azurerm` | 0.10.2 | azurerm `>=3.117,<5` | RBAC、Network ACL、vault PEに対応。Secret入力は使用しない。 |
| Azure AI Services | `Azure/avm-res-cognitiveservices-account/azurerm` | 0.11.1 | azurerm `>=4.17,<5`、azapi `~>2.5` | `AIServices`、Project Management、account PE、AI系3Zoneに対応。v0.11以降はPE実装変更に注意。 |
| 管理VM | `Azure/avm-res-compute-virtualmachine/azurerm` | 0.21.0 | azurerm `>=3.116,<5`、tls `~>4.0` | NIC内部作成、固定Private IP、Public IPなし、SSH公開鍵、AADSSHLoginForLinux拡張に対応。v0.19で大きな破壊的変更あり。 |

root moduleでは、全moduleの共通制約を満たすTerraform `>=1.10,<2.0`、AzureRM `~>4.77.0`、AzAPI `~>2.8` を指定し、lock fileで実バージョンとchecksumを固定します。補助ProviderはAVMが実際に要求する `modtm`、`random`、`time`、`tls` だけを定義しています。

## AVMを使わず直接定義したresource

`azurerm_cognitive_account_project` だけをroot `main.tf` で直接定義しています。確認時点で要件を満たす公開済みTerraform AVMがなく、AzureRM Provider 4.77.0に正式resourceが存在するためです。

AI Services側では、Project作成の前提となる次の設定をCognitive Services AVMへ指定しています。

- `kind = "AIServices"`
- `allow_project_management = true`
- System Assigned Managed Identity
- `custom_subdomain_name`

## 第3段階で検討するAVM

導入時点で最新版、破壊的変更、Provider制約を再確認します。

| 用途 | Module source |
|---|---|
| User Assigned Managed Identity | `Azure/avm-res-managedidentity-userassignedidentity/azurerm` |
| ACR | `Azure/avm-res-containerregistry-registry/azurerm` |
| Container Apps Environment | `Azure/avm-res-app-managedenvironment/azurerm` |
| Container App | `Azure/avm-res-app-containerapp/azurerm` |
| Role Assignment補完 | `Azure/avm-res-authorization-roleassignment/azurerm` |

## 公式確認先

- AVM index: <https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/>
- Terraform Registry: <https://registry.terraform.io/namespaces/Azure>
- AzureRM Cognitive Account Project: <https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account_project>
- Microsoft Entra ID SSH for Linux VM: <https://learn.microsoft.com/entra/identity/devices/howto-vm-sign-in-azure-ad-linux>
- Azure default outbound access: <https://learn.microsoft.com/azure/virtual-network/ip-services/default-outbound-access>
