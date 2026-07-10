# state移行方針

## 確認結果

作業時点のGitリポジトリ内には `terraform.tfstate`、追跡中の `terraform.tfvars`、`backend.hcl` はありませんでした。Azure Storage backendや既存Azureリソースの実在は、このローカル環境だけでは確認できません。

既存stateがある場合は、この再構成後のコードをそのままapplyしないでください。

## 移行が必要な理由

旧構成は自作module内の `azurerm_*` resourceを使用していました。新構成は、rootからAVMを呼び出し、AVM内部でAzAPI resourceを使用する箇所があります。

例:

```text
旧: module.network.azurerm_virtual_network.this
新: module.virtual_network.azapi_resource.vnet
```

resource typeが変わる場合、`moved` blockや単純な `terraform state mv` だけでは移行できない可能性があります。

## 既存環境がある場合の手順

1. 現在のbackend設定とstateをバックアップします。
2. `terraform state list` と `terraform state show` で旧resource addressとAzure Resource IDを記録します。
3. 新AVM内部のresource typeとimport IDを確認します。
4. resourceごとに `moved`、`state mv`、`import`、再作成のどれを使うか決めます。
5. `terraform plan` をレビューし、意図しないdestroy/recreateがないことを確認します。
6. 特にVNet、Storage Account、Key Vault、AI Servicesの置換が出た場合はapplyを止めます。

PoC環境を削除してよい場合は、既存Resource Groupを削除してfresh applyする方が単純です。ただし、削除前にstateとデータの保全を確認してください。

## backend state key

- bootstrap: `ocr-demo/bootstrap/terraform.tfstate`
- solution: `ocr-demo/solution/terraform.tfstate`

backend変更時は `terraform init -migrate-state` または、移行せず設定だけを再初期化する場合に `terraform init -reconfigure` を使います。
