# StreamlitモックとAzure基盤の責任分界

## まず理解すること

このリポジトリには、次の2種類のコードがあります。

| 種類 | 場所 | 役割 |
|---|---|---|
| インフラコード | `terraform/` | AzureのVNet、VM、Storage、Key Vault、Private Endpoint等を作る |
| アプリコード | `app/` | 利用者が操作する画面と、将来の業務フローを確認する |

Terraformを実行しても `app/` は自動デプロイされません。反対に、ローカルでStreamlitを起動してもAzureリソースは作られません。

## 現在の処理

```text
ブラウザー
  ↓
Streamlit
  ├─ 一時ログインコードをローカル照合
  ├─ 固定サンプルの事業性評価結果を表示
  ├─ メモリ内だけで履歴と監査ログを保持
  └─ openpyxlで6シートの事業性評価Excelを生成
```

Azure AI、Blob Storage、Key Vault、FastAPIへは接続しません。アップロードされたファイルも解析・保存しません。

## 将来の本番処理

```text
利用者
  ↓ HTTPS、閉域経路
Streamlit
  ↓ 内部API
FastAPI
  ├─ 認証・認可
  ├─ ファイル検査
  ├─ Document Intelligenceで決算書・参考資料を読取
  ├─ Azure OpenAIで顧客属性、財務、取引先、SWOT、事業課題を整理
  ├─ Blob入出力
  ├─ 履歴・監査ログ
  └─ Excel生成
```

Streamlitは画面に集中させ、Secret、Azure資格情報、Storage Key、AI API Keyを保持させません。FastAPIも固定キーよりManaged Identityを優先し、必要なAzure RBACだけを付与します。

## Azureリソースとの対応

| アプリの要件 | フェーズ2で作成済みの土台 | フェーズ4で追加するもの |
|---|---|---|
| 原本と成果物の保存 | Storage Account、Blob Private Endpoint、Private DNS | Blob Container、Managed Identity、RBAC |
| Secret保管 | Key Vault、vault Private Endpoint、Private DNS | Secret登録手順、Managed Identity、RBAC |
| 文書読取・事業性評価 | Azure AI Services、Private Endpoint、Private DNS | Document Intelligence・Azure OpenAIのAPI実装、プロンプト、RBAC |
| アプリ実行 | ACA用Subnet | ACR、Container Apps Environment、UI/API Container App |
| ログ | Log Analytics Workspace | アプリ診断設定、監査ログ設計、アラート |

## 初心者向けの切り分け方

問題が起きたら、次の順に確認します。

1. VNet内でPrivate DNS名がPrivate IPへ解決されるか
2. Private EndpointへTCP 443で到達できるか
3. Managed Identityがトークンを取得できるか
4. RBACのRoleとscopeが正しいか
5. FastAPIがAzureサービスへ正しい要求を送っているか
6. StreamlitがFastAPIへ正しい要求を送っているか

この順番にすると、「画面の問題」と「Azureネットワークの問題」を混同しにくくなります。
