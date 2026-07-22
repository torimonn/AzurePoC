# 案件書v2.0 照合結果

> このファイルは以前の案件書v2.0を確認した履歴です。現在の判断は [`latest-handover-compliance.md`](latest-handover-compliance.md) を優先してください。

確認日: 2026-07-21

対象: `AI業務アシスト_Azure閉域基盤_案件書_v2.0.docx`

## 結論

2026-07-21時点のTerraformは、案件書v2.0のフェーズ2「bootstrap」とフェーズ3「Spoke初期基盤」に適合していました。フェーズ7以降のACR、Container Apps、アプリ用Blob Container、Dify等は、依存関係を増やさないため追加していませんでした。

既存Azureリソース名とbackend keyの `ocr-demo` は、案件書付録Aの「旧名称を基盤名として残存可能」に従い維持します。説明、README、既定タグはAI業務アシストへ更新しています。

## 実装済み

| 案件書v2.0の要件 | 実装状況 |
|---|---|
| bootstrapとsolutionの2 root module | 実装済み |
| State用RG、Storage、tfstate Container、実行者RBAC | bootstrapで実装済み |
| State Storageは初期Cloud Shellから到達可能 | Public Network Access有効、Network Rule Allowを初期値として実装 |
| State StorageはShared Keyを使わずEntra ID認証 | Shared Key無効、OAuth既定、backendの `use_azuread_auth` を実装 |
| Spoke VNet `10.30.0.0/24` | 実装済み |
| ACA用Subnet `10.30.0.0/25` | `Microsoft.App/environments` delegation付きで実装済み |
| Private Endpoint用Subnet `10.30.0.128/26` | Private Endpoint network policies無効、UDRなし |
| 管理VM用Subnet `10.30.0.192/28` | 実装済み |
| 管理VM固定IP `10.30.0.196` | 実装済み |
| 管理VMのPublic IPなし | 実装済み |
| 管理VMのEntra ID SSH | System Assigned IdentityとAADSSHLoginForLinuxを実装 |
| Hub BastionからのSSH制限 | CIDR設定時だけTCP/22許可ルールを作成 |
| AI用3Zone、Blob、Key VaultのPrivate DNS | 5ZoneとSpoke VNet Linkを実装済み |
| Azure AI、アプリStorage、Key VaultのPrivate Endpoint | 各対象AVMで実装済み |
| PaaSのPublic Network Access無効 | 3サービスともコードで `false` に固定 |
| Network Ruleの既定Deny | 3サービスともコードで `Deny` に固定 |
| アプリ用StorageのEntra ID認証 | OAuthを既定とし、Shared Keyを `false` に固定 |
| 初期UDR無効 | `enable_udr_to_hub_firewall = false` |
| UDRをPE用Subnetへ付けない | ACA用と管理VM用だけへ条件付き関連付け |
| State Storageの段階的Private化 | solutionに条件付きState Storage PEを実装 |
| Key Vault SecretをTerraformで作らない | Secret resourceなし |
| 初期Cloud Shellからアプリ用Blob Containerを作らない | Container resourceなし |
| AVMをrootから固定バージョンで直接利用 | 実装済み |
| 実tfvars、backend、state、秘密鍵をGitへ入れない | `.gitignore`で除外 |
| Terraform、Python、Shell等のLF統一 | `.gitattributes`を追加 |

## 今回単純化した点

| 変更前 | 変更後 | 理由 |
|---|---|---|
| `enable_*_private_only_access` と公開設定を二重指定 | PaaSはコードでPublic無効、Denyに固定 | 案件書の固定要件をそのまま読めるようにする |
| アプリ用StorageのShared Keyを一時的に有効化 | Shared Keyを無効に固定 | 現行Storage AVMはAzAPIとEntra IDで管理され、初期基盤ではデータプレーンresourceを作らないため |
| `blob_container_name = "documents"` | 初期solutionから変数とoutputを削除 | v2.0は用途別6 Containerであり、作成は後続フェーズ |
| OCR-Demo中心のREADME | AI業務アシストへ更新 | 案件の現在名称と機能範囲を明確にする |
| Git改行・オフライン資材ルールが不足 | `.gitattributes` と除外ルールを追加 | Windows/Linux間の差分と大容量資材混入を防ぐ |

moduleの `count`、resource address、Azureリソース名は変更していません。既存Stateがある場合に不要な再作成を起こさないためです。

## 後続フェーズ

| 要件 | 実装予定フェーズ |
|---|---:|
| Azure Bastion、Hub Peering、Firewall、DNS Resolver、ExpressRoute | 4から6、共通基盤担当と実施 |
| ACRとACR用Private DNS、Private Endpoint | 7 |
| ACA Workload profiles Environment | 7 |
| StreamlitとFastAPIのContainer App | 7 |
| User Assigned Managed IdentityとStorage/KV RBAC | 7 |
| 用途別6 Blob Container | 7 |
| Document Intelligence、Speech、Whisper、OpenAIの最終選定と接続 | 8 |
| 履歴、ジョブ状態、監査ログ | 8 |
| QueueとWorker | 必要性確認後 |
| Dify専用Subnet、VM、Docker Compose | 9 |
| バックアップ、保持、復旧、更新 | 10 |

## 実装前に確定が必要な項目

- Azure BastionのSKU、費用、利用期間
- Hub Firewall Private IP、許可先、戻り経路
- オンプレDNSとPrivate DNSの連携方式
- 管理VMログインRoleを付与するEntraユーザーまたはグループ
- Azure AI Document Intelligence、Content Understanding、Speech、Whisperの最終選定
- アプリ認証の暫定期間とAD、Entra IDへの移行方式
- 履歴保存先、データ保持期間、削除方法
- ファイル検査とマルウェア対策
- Dify VMサイズ、ディスク、バックアップ
- Azure上の既存resourceと既存Stateの有無

## 公式仕様の再確認

2026-07-21時点で次を確認しています。

- ACA Workload profiles環境は `/27` 以上でVNet統合でき、`Microsoft.App/environments` delegationが必要です。採用した `/25` は要件を満たします。
- State backendは `use_azuread_auth` とAzure CLIまたはManaged Identityを利用できます。
- AADSSHLoginForLinuxはSystem Assigned Managed Identityを必要とします。
- Storage、VNet、VM、AI Services、Key Vaultの採用AVM固定版はTerraform Registryのlatestと一致しています。

参照先は [`avm-module-selection.md`](avm-module-selection.md) と [`beginner-guide.md`](beginner-guide.md) にまとめています。
