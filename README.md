# Azure OCR-Demo

Azure OCR-Demo PoCのTerraformリポジトリです。Terraformコードは [`terraform/`](terraform/) 配下にあり、state基盤とOCR-Demo本体を別々のroot moduleとして管理します。

```text
terraform/
├─ bootstrap/  # Terraform state用Resource Group、Storage Account、Blob Container
└─ solution/   # OCR-Demo第1段階のAzure基盤全体
```

公開済みのAzure Verified Modules（AVM）をroot moduleから直接呼び出します。AVMソースは `terraform init` で取得し、このGitリポジトリにはコピーしません。

詳細な実行手順は [`terraform/README.md`](terraform/README.md) を参照してください。
