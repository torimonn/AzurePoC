# bootstrap root module

Terraform state専用のResource Group、Storage Account、`tfstate` Blob Containerを作成します。OCR-Demoアプリ用Storage Accountとは分離しています。

## 初回構築

1. `terraform.tfvars.example` を参考に、Git管理しない `terraform.tfvars` を作成します。
2. Storage Account名をAzure全体で一意な値へ変更します。
3. `az ad signed-in-user show --query id -o tsv` などで実行者のMicrosoft Entra Object IDを取得し、`state_admin_principal_id`へ設定します。
4. `backend.tf.example` はまだ有効化せず、local stateでbootstrapを作成します。

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

`apply`はplanレビュー後に実行してください。

## bootstrap stateのAzure Storage移行

state用Storage AccountとContainerの作成後、`backend.tf.example` をGit管理外の `backend.tf` として配置し、次のようにbackend設定を渡してlocal stateを移行します。

```bash
terraform init -migrate-state \
  -backend-config="resource_group_name=rg-ocr-demo-tfstate" \
  -backend-config="storage_account_name=<tfstate-storage-account-name>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=ocr-demo/bootstrap/terraform.tfstate" \
  -backend-config="use_azuread_auth=true"
```

backendへStorage Account Keyや接続文字列は保存しません。Cloud ShellではAzure CLI認証、管理VMではManaged IdentityまたはAzure CLIによるMicrosoft Entra ID認証を使用します。

Cloud Shellから初回作成できるよう、exampleではstate StorageのPublic Network AccessとNetwork Ruleの`Allow`を使用しています。閉域管理VMから到達できるPrivate Endpoint、Firewall許可、名前解決が準備できた時点で、組織のネットワーク方針に従って制限してください。

AVM telemetryは、組織・セキュリティレビューが完了するまで一時的に無効化しています。
