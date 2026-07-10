# 閉域管理VMへの持ち込み

通常のGitリポジトリにはAVMソースとProvider binaryを保存しません。オンラインのCloud Shellで固定版moduleとProviderを取得し、閉域配布用パッケージを生成します。

## Cloud Shell側

```bash
cd terraform/solution
./scripts/prepare-offline-package.sh
```

生成物は `terraform/dist/ocr-demo-offline.tar.gz` です。次を含みます。

- solutionのTerraformコード、README、docs、scripts
- `.terraform.lock.hcl`
- 取得済み `.terraform/modules` と `modules.json`
- `linux_amd64`用Provider filesystem mirror
- `terraform.rc.example`
- `MANIFEST.md`

実 `terraform.tfvars`、実 `backend.hcl`、state、plan、Secretは含めません。承認された安全な手段で別途配置してください。

## 管理VM側

```bash
export TF_CLI_CONFIG_FILE=/opt/terraform/terraform.rc
cd /opt/terraform/ocr-demo/solution

terraform init \
  -get=false \
  -reconfigure \
  -backend-config=backend.hcl

terraform validate
terraform plan
```

`terraform.rc` のfilesystem mirror pathは、実際の展開先に合わせて変更します。

PoCでは取得済みmodule treeを利用できます。本番・継続運用では、社内GitへのAVM保管、Private Module Registry、明示的なvendor管理、社内Provider network mirrorのいずれかを検討してください。
