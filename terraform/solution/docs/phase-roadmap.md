# OCR-Demo フェーズ別ロードマップ

## 目的

初めからすべてを作ると、通信障害がネットワーク、DNS、認証、アプリのどこにあるのか判断しにくくなります。そのため、更新案件書に合わせて構築を6フェーズへ分けます。

添付されたStreamlit画面モックはソース確認用としてリポジトリへ格納済みですが、現在のTerraformではAzureへデプロイしません。

## 全体ロードマップ

| フェーズ | 主な内容 | 実行場所 | 現在の状況 |
|---:|---|---|---|
| 0 | Subscription、権限、命名、既存state、Hub前提を確認 | Portal、ローカルWindows | 手順を文書化 |
| 1 | State用RG、Storage、`tfstate` Container、RBAC | 初回はCloud Shell | `terraform/bootstrap` で実装済み |
| 2 | VNet、3 Subnet、NSG、DNS、管理VM、AI、Storage、Key Vault、PE | Cloud Shell | `terraform/solution` で実装済み |
| 3 | Hub Peering、ExpressRoute、DNS、Firewall、SSH、UDRの疎通 | 共通基盤、管理VM | 他チームと調整後に実施 |
| 4 | ACR、Container Apps、Streamlit、FastAPI、Managed Identity、RBAC | 管理VM | 画面モックだけ格納済み。Azure側は未実装 |
| 5 | Entra ID認証、監視、保持、バックアップ、復旧、変更管理 | 関係担当 | 未実装 |

## 現在作るもの

- Terraform State用Storage
- Resource Group
- Log Analytics Workspace
- Spoke VNet `10.30.0.0/24`
- ACA用Subnet `10.30.0.0/25`
- Private Endpoint用Subnet `10.30.0.128/26`
- 管理VM用Subnet `10.30.0.192/28`
- 管理VM用NSG
- Public IPなし管理VM `10.30.0.196`
- AI用3Zone、Blob、Key Vault用Private DNS Zone
- Azure AI ServicesとAzure AI Foundry Project
- アプリ用Storage Account
- Key Vault
- 各PaaSのPrivate Endpoint
- Hub Firewall向けUDRの条件付き定義
- State Storage用Private Endpointの条件付き定義

## 現在作らないもの

- ACRとACR用Private Endpoint
- Container Apps EnvironmentとContainer App
- FastAPI
- アプリ用Managed IdentityとRole Assignment
- アプリ用Blob Container
- Key Vault Secret
- Hub-Spoke Peering、Firewall Rule、DNS Private Resolver
- Dify用SubnetとVM

`app/` にあるStreamlitは「作らないもの」ではなく、Azureへまだ配置しないソースコードです。ローカルで画面を確認できます。

## フェーズ3へ進む条件

1. `terraform apply` 後のAzureリソースとstateが一致している
2. 管理VMにPublic IPがない
3. 管理VMのPrivate IPが `10.30.0.196` である
4. AI、Blob、Key VaultのPrivate DNSがPrivate EndpointのIPを返す
5. Hub、ExpressRoute、Firewall、DNSの責任担当が決まっている
6. 開発環境から管理VMまでの往復経路とSSH許可元が決まっている

## フェーズ4へ進む条件

1. 承認済みの経路で管理VMへ接続できる
2. 管理VMからAzure backendへ接続して `terraform plan` が成功する
3. Hub Firewall経由の必要な外向き通信が確認できる
4. ACR Pull、Managed Identity、監視ログの通信方針が決まっている
5. StreamlitとFastAPIの責任分界がレビュー済みである
6. ファイル検査、データ保持、監査ログの要件が決まっている

## フェーズ4の最小構成

最初は次の構成だけで業務フローを確認します。

```text
利用者
  ↓
Streamlit Container App  # 画面、入力、結果確認、ダウンロード
  ↓
FastAPI Container App    # 認証境界、入力検査、AI呼出し、Storage制御
  ├─ Azure AI
  ├─ Blob Storage
  └─ Key Vault
```

長時間処理が必要と確認されるまでは、QueueやWorkerを追加しません。Difyも更新案件書の対象外なので、利用目的と運用担当が確定するまで追加しません。

## 構成を増やすときのルール

- 前フェーズの疎通確認を終えてから次へ進む
- 障害原因を切り分けられる最小単位で追加する
- Public Network Accessを一時的に開く場合は、理由、期限、戻し方を記録する
- Secret値をTerraformコード、tfvars、output、stateへ入れない
- AI結果を自動確定せず、職員の確認・修正を必須にする
