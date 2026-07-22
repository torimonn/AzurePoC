# 初心者向け OCR-Demo Azure閉域基盤ガイド

## 1. この資料の目的

この資料は、TerraformやAzureネットワークを初めて扱う人が、コードを暗記せずに「何を、なぜ作るのか」を理解するための入門書です。

読み終えた時点で、次の内容を説明できることを目標にします。

- `bootstrap` と `solution` を分ける理由
- `terraform init`、`plan`、`apply` の違い
- VNet、Subnet、NSG、UDRの役割
- Private EndpointとPrivate DNS Zoneを両方作る理由
- Cloud Shellで作成できても、通信確認できないものがある理由
- 管理VMへ実行場所を切り替えてからState StorageをPrivate化する理由
- 現在のTerraformが担当する範囲と、後続フェーズの範囲

## 2. 最初に全体像をつかむ

このリポジトリが現在Terraformで作るものはアプリ本体ではなく、アプリを後から安全に載せるための初期Azure基盤です。

```text
Azure Cloud Shell
  │ Terraformで管理プレーン操作
  ▼
State Storage ─ TerraformがAzureの状態を記録

Spoke VNet 10.30.0.0/24
├─ ACA用Subnet 10.30.0.0/25
│    後続でStreamlitとFastAPIを配置
├─ Private Endpoint用Subnet 10.30.0.128/26
│    Azure AI、Storage、Key VaultへのPrivate接続口
├─ 管理VM用Subnet 10.30.0.192/28
│    管理VM 10.30.0.196、Public IPなし
└─ 将来予約 10.30.0.208-255
```

初期構築ではCloud Shellを使います。ただし、標準Cloud ShellはこのSpoke VNetの中に存在しません。そのため、Azureリソースの作成はできても、Private Endpoint経由のBlob読書きやKey Vault Secret操作までは確認できません。

## 3. Terraformの基本

### 3.1 Terraformとは

Terraformは、Azure Portalで行う設定をコードとして宣言する仕組みです。

たとえば「この名前のVNetと3つのSubnetが必要」とコードへ書き、Terraformに現在のAzureと比較させます。Terraformは差分を `plan` として表示し、承認後の `apply` でAzureへ反映します。

### 3.2 よく出る用語

| 用語 | 意味 | このリポジトリでの例 |
|---|---|---|
| Provider | Terraformから対象サービスを操作する部品 | `hashicorp/azurerm`、`Azure/azapi` |
| Resource | Azure上の1つの管理対象 | VNet、Private Endpoint、AI Project |
| Module | 複数のresourceや設定をまとめた再利用単位 | Azure Verified Modules |
| Root module | `terraform init` や `plan` を実行する最上位ディレクトリ | `bootstrap`、`solution` |
| Variable | 環境ごとに変える入力値 | Storage Account名、SSH公開鍵 |
| Local | root内部だけで使う計算済みの値 | Subnet map、DNS Zone map |
| Output | apply後に他作業で参照する値 | VNet ID、管理VM Private IP |
| State | Terraformが管理対象とAzure実体の対応を記録する台帳 | `terraform.tfstate` |
| Backend | Stateを保存する場所 | Azure Storage Blob |
| Lock file | Providerの実バージョンとchecksumを固定するファイル | `.terraform.lock.hcl` |

### 3.3 init、fmt、validate、plan、apply

| コマンド | 何をするか | Azureを変更するか |
|---|---|---|
| `terraform fmt -recursive` | HCLの字下げや配置を整える | 変更しない |
| `terraform init` | Provider、AVM、backendを準備する | 原則変更しない |
| `terraform validate` | 参照、型、構文の整合性を確認する | 変更しない |
| `terraform plan` | 現在とコードの差分を表示する | 変更しない |
| `terraform apply` | 確認した差分をAzureへ反映する | 変更する |
| `terraform output` | apply後の出力値を表示する | 変更しない |

`apply` より前に `plan` を保存し、追加、変更、削除を必ず確認します。特に `destroy`、`replace`、`-/+` が表示された場合は、その場で適用せず原因を確認します。

## 4. Azureネットワークの基本

### 4.1 VNetとSubnet

VNetはAzure内の専用ネットワーク全体、Subnetは用途ごとに区切った区画です。

`10.30.0.0/24` の `/24` は、先頭24bitがネットワーク部であることを表します。この範囲には256個のアドレスがありますが、Azureが各Subnetで一部を予約するため、すべてをVM等へ割り当てられるわけではありません。

管理VM用Subnet `10.30.0.192/28` の範囲は `10.30.0.192` から `10.30.0.207` です。Azure予約アドレスを避け、管理VMには `10.30.0.196` を固定で割り当てます。

### 4.2 NSG

Network Security Groupは、SubnetやNICへ適用する通信許可ルールです。

この構成では管理VM用NSGを作成します。`hub_azure_bastion_subnet_prefix` が設定されている場合だけ、そのCIDRからTCP/22を許可します。値が `null` の間はSSH許可ルールを作らないため、意図せず広い範囲へSSHを公開しません。

### 4.3 UDR

User Defined Routeは、通信の次の行き先を指定するルートです。

初期値は `enable_udr_to_hub_firewall = false` です。Hub接続と戻り経路を確認した後に有効化すると、ACA用Subnetと管理VM用Subnetの既定経路をHub Firewallへ向けます。Private Endpoint用SubnetにはRoute Tableを関連付けません。

### 4.4 Public IPを付けない意味

管理VMにはPublic IPを作りません。そのためインターネットからVMへ直接SSHできません。初期は承認済みAzure Bastion、Hub接続後はExpressRouteとHub経由でPrivate IPへ接続します。

Public IPを付けないことと、VMから外部へ一切通信しないことは別です。Entra ID SSH拡張の導入やOS更新には限定的な送信経路が必要になる場合があります。送信はHub Firewall等で明示的に制御します。

## 5. Private EndpointとDNS

### 5.1 Private Endpoint

Azure StorageやKey VaultはPaaSです。通常は公開FQDNを持ちますが、Private Endpointを作ると、VNet内のPrivate IPを使ってサービスへ接続できます。

Private Endpointは「サービスへ入るためのPrivate IP付きネットワークインターフェース」です。

### 5.2 Private DNS Zone

Private Endpointだけでは名前解決は完成しません。アプリは通常、IPアドレスではなく次のようなFQDNへ接続します。

```text
<storage-name>.blob.core.windows.net
<key-vault-name>.vault.azure.net
```

Private DNS ZoneとVNet Linkを作ることで、VNet内からこのFQDNを引いたときにPrivate EndpointのIPが返ります。

この初期基盤では次の5Zoneを作成します。

- `privatelink.cognitiveservices.azure.com`
- `privatelink.openai.azure.com`
- `privatelink.services.ai.azure.com`
- `privatelink.blob.core.windows.net`
- `privatelink.vaultcore.azure.net`

要点は、Private Endpointが「経路の入口」、Private DNS Zoneが「名前から入口を見つける仕組み」ということです。どちらか一方だけでは閉域通信を正しく確認できません。

## 6. 管理プレーンとデータプレーン

Azure操作は大きく2種類に分かれます。

| 区分 | 例 | Cloud Shellからの扱い |
|---|---|---|
| 管理プレーン | VNet、VM、Storage Account、Private Endpointを作る | Azure APIへ到達できれば実施可能 |
| データプレーン | Blobを読む、Secretを登録する、AI APIを呼ぶ | Private化後はSpoke内の実行環境が必要 |

Cloud ShellからPrivate Endpointを作成できても、Cloud Shell自体がSpoke内へ入ったわけではありません。そのため「Terraform apply成功」と「Private通信成功」は別の確認項目です。

## 7. なぜbootstrapとsolutionを分けるのか

TerraformのStateをAzure Storageへ保存したい一方、そのStorage Account自体もTerraformで作りたいという順序問題があります。

そこで2つのroot moduleに分けます。

```text
bootstrap
  1. local stateでState Storageを作る
  2. tfstate ContainerとRBACを作る
  3. bootstrap自身のstateをAzure Storageへ移す

solution
  4. Azure Storage backendを使って初期基盤を作る
```

`bootstrap` と `solution` は別のStateを持ちます。片方のStateにすべてを詰め込まず、State基盤と業務基盤のライフサイクルを分離しています。

## 8. ファイルの読み方

### 8.1 solution

| ファイル | 内容 | 最初に見るポイント |
|---|---|---|
| `terraform.tf` | TerraformとProviderのバージョン条件 | バージョンを勝手に上げない |
| `providers.tf` | AzureRMとAzAPIの認証設定 | Subscription指定方法 |
| `backend.tf` | Azure Storage backendを使う宣言 | 実値は `backend.hcl` に置く |
| `variables.tf` | 利用者が設定できる値 | 必須値とdefault |
| `locals.tf` | SubnetとDNS Zoneの組み立て | UDRの条件分岐 |
| `main.tf` | 実際に作るAzureリソース | 番号順に読む |
| `outputs.tf` | apply後に確認する値 | IP、ID、endpoint |
| `terraform.tfvars.example` | 入力値の記入例 | コピー後に実値へ変更 |

### 8.2 自動生成物

`terraform init` 後に作られる `.terraform/` は、ProviderとAVMのダウンロード先です。GitHubから取得したAVM本体に `AGENTS.md`、`.github`、`tests` 等が含まれる場合がありますが、この案件の手書きコードではありません。

削除しても `terraform init` で再生成されます。内容を案件コードとして修正したり、Gitへ登録したりしません。

## 9. apply前に設定する値

### 9.1 bootstrap

| 値 | 必須理由 |
|---|---|
| `state_storage_account_name` | Azure全体で一意である必要がある |
| `state_admin_principal_id` | State Blobへアクセスする実行者のObject ID |
| `subscription_id` | Azure CLIの選択中Subscriptionを使わない場合に設定 |

### 9.2 solution

| 値 | 必須理由 |
|---|---|
| `storage_account_name` | Azure全体で一意である必要がある |
| `key_vault_name` | Azure全体で一意である必要がある |
| `admin_ssh_public_key` | break-glass用。秘密鍵は入力しない |
| `admin_vm_login_principal_id` | TerraformでVMログインRoleを付ける場合に設定 |
| `hub_azure_bastion_subnet_prefix` | BastionからSSHを許可する段階で設定 |
| `hub_firewall_private_ip` | UDRを有効化する段階で設定 |

`terraform.tfvars.example` は例です。実値を入れた `terraform.tfvars` はGit管理しません。

## 10. 初期構築の順序

### 手順1: Azureの接続先を確認する

```bash
az account show --output table
az account set --subscription <subscription-id>
az account show --query id -o tsv
```

意図したSubscriptionであることを確認してからTerraformを実行します。

### 手順2: bootstrapを準備する

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars
```

`terraform.tfvars` のStorage Account名とObject IDを実値へ変更します。

### 手順3: State Storageを作る

```bash
terraform fmt -recursive
terraform init
terraform validate
terraform plan -out=bootstrap.tfplan
terraform show -no-color bootstrap.tfplan
terraform apply bootstrap.tfplan
```

初回はlocal stateです。planに意図しない削除や置換がないことを確認してからapplyします。

### 手順4: bootstrap stateをAzure Storageへ移す

`backend.tf.example` をGit管理外の `backend.tf` として用意し、READMEの `terraform init -migrate-state` を実行します。backendにはStorage Account Keyや接続文字列を保存せず、Cloud Shellでは `use_azuread_auth = true` と `use_cli = true` でMicrosoft Entra ID認証を使います。

### 手順5: solutionを準備する

```bash
cd ../solution
cp terraform.tfvars.example terraform.tfvars
cp backend.hcl.example backend.hcl
```

Storage Account名、Key Vault名、SSH公開鍵等を実値へ変更します。

### 手順6: 初期基盤のplanとapply

```bash
terraform fmt -recursive
terraform init -reconfigure -backend-config=backend.hcl
terraform validate
terraform plan -out=ocr-demo.tfplan
terraform show -no-color ocr-demo.tfplan
terraform apply ocr-demo.tfplan
```

保存したplanファイルをapplyすることで、レビューした内容と適用内容のずれを防ぎます。

## 11. planの読み方

先に末尾の集計を確認します。

```text
Plan: X to add, Y to change, Z to destroy.
```

次に記号を確認します。

| 記号 | 意味 | 判断 |
|---|---|---|
| `+` | 新規作成 | 名前、リージョン、CIDRを確認 |
| `~` | 既存リソースの更新 | 変更属性と影響を確認 |
| `-` | 削除 | 原則停止して理由を確認 |
| `-/+` | 削除後に再作成 | ID、IP、データ消失の影響を確認 |

この案件では特にVNet、Storage Account、Key Vault、Private Endpoint、State Storageの再作成がないかを確認します。

## 12. 初期構築後の疎通確認

Cloud Shellではなく、管理VMまたは承認済み閉域端末から確認します。

```bash
nslookup <storage-account-name>.blob.core.windows.net
curl -I https://<storage-account-name>.blob.core.windows.net/

nslookup <key-vault-name>.vault.azure.net
curl -I https://<key-vault-name>.vault.azure.net/
```

`nslookup` でPrivate EndpointのIPが返ることを確認します。`curl` が401や403を返す場合、認証には失敗していてもネットワーク到達には成功している可能性があります。タイムアウトする場合はDNS、NSG、Route、Firewall、Private Endpointの状態を順に確認します。

## 13. State StorageのPrivate化

この作業は、管理VMから現在のbackendへ到達できることを確認してから行います。

1. 管理VMへTerraformコードと固定済みProviderを配置する
2. 管理VMから現在のState Storageへ `terraform init` と `terraform plan` が成功することを確認する
3. bootstrap outputからState StorageのResource IDと名前を取得する
4. solutionで `enable_state_storage_private_endpoint = true` にする
5. State Storage用Private Endpointを作る
6. 管理VMでFQDNがPrivate IPへ解決されることを確認する
7. 管理VMから再度 `terraform plan` が成功することを確認する
8. 最後にbootstrap側でPublic Network Accessを無効化する

管理VMからの確認前にPublic Network Accessを無効化すると、Cloud ShellからStateを読めなくなり、復旧作業が難しくなります。

## 14. よくある誤解とエラー

### Private Endpointを作ったのでCloud ShellからBlobを読める

誤りです。Private EndpointはSpoke VNet内のPrivate IPです。標準Cloud ShellがそのVNetへ接続されていなければ到達できません。

### Shared KeyとPublic Network Accessは同じ設定である

誤りです。Shared Keyは認証方式、Public Network Accessは通信経路の設定です。このsolutionではShared KeyとPublic Network Accessを無効にし、Entra ID認証を既定にしています。Storage AVMはAzAPIとEntra IDで管理するため、初期基盤のTerraform applyにShared Keyは必要ありません。

### `terraform validate` が成功したので安全にapplyできる

`validate` は主に構文と型の確認です。Azure上の既存リソースとの差分や破壊的変更は `plan` で確認します。

### Storage Account名またはKey Vault名が重複する

これらの名前はAzure全体で一意です。末尾へ組織固有の英数字を付けて変更します。

### Entra ID SSH拡張が失敗する

System Assigned Managed Identity、VMログインRole、VM Agent、必要な外向き通信を確認します。Hub未接続で送信経路がない場合、拡張のパッケージ取得に失敗する可能性があります。

## 15. 変更してよい場所と慎重に扱う場所

通常変更するのは、Git管理外の `terraform.tfvars` と `backend.hcl` です。

`main.tf` のmodule source、module version、Resource Group名、VNet CIDR、backend keyを変更すると、広い範囲へ影響する可能性があります。変更前に案件書、既存State、Azure実体を確認します。

`.terraform.lock.hcl` は固定Providerの証拠なのでGitへ登録します。`.terraform/` は自動生成物なので登録しません。

## 16. 現在作らないもの

次の項目は必要性がないのではなく、依存関係と確認順序のため後続に分けています。

- ACR
- Azure Container Apps Environment
- Streamlit Container App
- FastAPI Container App
- Managed Identityとアプリ用RBAC
- アプリ用Blob Container
- QueueとWorker
- Hub Firewall、Peering、DNS Private Resolver

実装順は [`phase-roadmap.md`](phase-roadmap.md) を参照してください。

## 17. 最低限覚えるポイント

1. `bootstrap` を先に作り、State保存先を用意する
2. `solution` は初期Azure基盤だけを作る
3. `plan` を確認してから、保存したplanを `apply` する
4. PaaSはPublic Network Access無効、Private EndpointとDNSをセットで考える
5. Cloud Shellでの作成成功と、閉域内からの通信成功は別物
6. State StorageのPrivate化は管理VMへの切替後に行う
7. 実tfvars、backend、state、秘密鍵、成果物をGitへ入れない

## 18. 公式資料

- Terraform AzureRM backend: <https://developer.hashicorp.com/terraform/language/backend/azurerm>
- Azure Container Apps custom VNet: <https://learn.microsoft.com/azure/container-apps/custom-virtual-networks>
- Linux VMのMicrosoft Entra ID SSH: <https://learn.microsoft.com/entra/identity/devices/howto-vm-sign-in-azure-ad-linux>
- Azure Verified Modules index: <https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/>
- Storage Account AVM: <https://registry.terraform.io/modules/Azure/avm-res-storage-storageaccount/azurerm/latest>
