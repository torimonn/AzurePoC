# OCR-Demo Terraform

このディレクトリには、独立した2つのTerraform root moduleがあります。

- `bootstrap`: Azure Storage backend用のResource Group、Storage Account、`tfstate` Blob Container、実行者向けRBACを作成します。
- `solution`: OCR-Demo第1段階のネットワーク、Private DNS、Private Endpoint、Azure AI Services、Storage Account、Key Vault、Log Analytics、管理VMを作成します。

`bootstrap`を先にlocal stateで作成し、その後にAzure Storage backendへstateを移行してから`solution`を初期化します。各ディレクトリのREADMEにコマンド例を記載しています。

AVM telemetryは、組織・セキュリティレビューが完了するまで一時的に無効化しています。
