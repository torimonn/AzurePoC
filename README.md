# OCR-Demo Azure閉域基盤 / AI業務アシスト画面モック

小規模な社内AIアプリを閉域Azureへ配置するためのリポジトリです。現在は、TerraformによるAzure基盤と、将来の画面像を確認するStreamlitモックを管理しています。

Azureリソース名、Terraform state key、Terraform側の案件名には `ocr-demo` を維持しています。添付された画面モックは「AI業務アシスト」という表示名です。既存リソースの不要な再作成を避けるため、両者を一括で改名していません。

## 現在の構成

```text
AzurePoC/
├─ app/                  # Streamlit画面モック。Azureへは未接続
└─ terraform/
   ├─ bootstrap/        # Terraform state用Storageを作る独立root module
   └─ solution/         # VNet、管理VM、Private DNS、AI、Storage、Key Vault
```

現時点の `terraform apply` でStreamlitアプリ、ACR、Container Apps、FastAPIは作成されません。画面モックとAzure基盤は、意図的に別フェーズへ分けています。

## 読む順番

1. [`terraform/solution/docs/beginner-guide.md`](terraform/solution/docs/beginner-guide.md) - TerraformとAzure閉域構成を初歩から理解する
2. [`terraform/solution/docs/phase-roadmap.md`](terraform/solution/docs/phase-roadmap.md) - 今作るものと後で作るものを確認する
3. [`terraform/solution/docs/latest-handover-compliance.md`](terraform/solution/docs/latest-handover-compliance.md) - 更新案件書との照合結果を確認する
4. [`terraform/README.md`](terraform/README.md) - 2つのTerraform root moduleを確認する
5. [`app/README.md`](app/README.md) - 画面モックをローカルで起動する

## 自動生成物について

`terraform init` が作る `.terraform/` と、その配下のAVMソースは自動生成物です。Gitへ登録しません。リポジトリでレビューする対象は、root moduleのTerraformコード、アプリのソース、ドキュメントです。

## GitHubへの反映方針

変更は作業ブランチで確認し、直接mainへpushせずPull Requestでレビューしてから取り込みます。
