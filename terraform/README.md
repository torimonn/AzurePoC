# OCR-Demo Azure閉域基盤 Terraform

このディレクトリには、独立した2つのTerraform root moduleがあります。

- `bootstrap`: Azure Storage backend用のResource Group、Storage Account、`tfstate` Blob Container、実行者向けRBACを作成します。
- `solution`: OCR-Demoの初期ネットワーク、Private DNS、Private Endpoint、Azure AI Services、Storage Account、Key Vault、Log Analytics、管理VMを作成します。

`bootstrap`を先にlocal stateで作成し、その後にAzure Storage backendへstateを移行してから`solution`を初期化します。管理VMへ実行場所を切り替えた後、solutionからState Storage用Private Endpointを追加し、疎通確認後にState StorageのPublic Network Accessを無効化します。各ディレクトリのREADMEにコマンド例を記載しています。

AVM telemetryは、組織・セキュリティレビューが完了するまで一時的に無効化しています。

TerraformやAzureの用語から確認したい場合は、先に [`solution/docs/beginner-guide.md`](solution/docs/beginner-guide.md) を参照してください。
