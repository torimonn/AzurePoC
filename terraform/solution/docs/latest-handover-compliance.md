# 更新案件書との照合結果

確認日: 2026-07-22

対象: `OCR-Demo_Azure閉域基盤_引継ぎ案件書 (1).docx`

文書内の版: 1.0（作成日 2026-07-18）

## 結論

現行Terraformは、更新案件書のフェーズ1「bootstrap」とフェーズ2「Spoke土台」に適合しています。添付されたStreamlitアプリは将来画面のモックとして `app/` へ取り込みましたが、TerraformからAzureへデプロイしません。

案件書の内部版は1.0で、以前確認した案件書v2.0より番号と作成日が古く見えます。このため、Azureリソースを破壊的に改名せず、今回の文書で再確認できた基盤要件を優先し、以前の照合資料は履歴として残しています。

## Terraformの適合状況

| 案件書の要件 | 実装状況 |
|---|---|
| `bootstrap` と `solution` の2 root module | 実装済み |
| AVMをrootから固定バージョンで直接利用 | 実装済み |
| State用Storageとアプリ用Storageを分離 | 実装済み |
| VNet `10.30.0.0/24` | 実装済み |
| ACA用Subnet `10.30.0.0/25` | 実装済み |
| Private Endpoint用Subnet `10.30.0.128/26` | 実装済み、UDRなし |
| 管理VM用Subnet `10.30.0.192/28` | 実装済み |
| 管理VM `10.30.0.196` | Static Private IPで実装済み |
| 管理VMのPublic IPなし | Public IP resourceなし、NICにも関連付けなし |
| SSH公開鍵認証 | 公開鍵必須、秘密鍵用variable/outputなし |
| Entra ID SSHは後から選択可能 | 初期値を `false` とし、明示的な有効化時だけ拡張を作成 |
| AI用Private DNS Zone 3個 | 維持 |
| Blob、Key Vault用Private DNS Zone | 維持 |
| AI、Blob、Key VaultのPrivate Endpoint | 実装済み |
| PaaSのPublic Network Access無効 | AI、アプリStorage、Key Vaultで固定 |
| 初期UDR無効 | `enable_udr_to_hub_firewall = false` |
| DNS Private ResolverをSpokeに作らない | resourceなし |
| Key Vault SecretをTerraformで作らない | resourceなし |
| アプリ用Blob Containerを初期作成しない | resourceなし |
| ACR、Container Appsを初期作成しない | resourceなし |
| State Storageを段階的にPrivate化 | 条件付きPrivate Endpointを実装済み |

## アプリZIPの確認結果

`ai_work_assist_streamlit.zip` は、18ファイルのStreamlit画面モックでした。絶対パス、親ディレクトリ参照、シンボリックリンク、仮想環境、Git管理情報、秘密鍵形式のファイルは含まれていませんでした。

取り込み時に次を修正しました。

- 固定のデモログインコードをソースから削除
- `TEMP_LOGIN_CODE` が未設定なら認証を失敗させる
- パスワード欄を自動入力しない
- 非rootユーザーで動かすDockerfileを追加
- 認証とExcel生成の単体テストを追加
- 画面モックと本番機能の違いを日本語READMEへ明記
- 添付のモバイル画面イメージ5枚を `app/docs/screenshots/` へ格納

## 文書・実物間で確認が必要な点

| 項目 | 案件書 | 現在の実物・対応 |
|---|---|---|
| 対象リポジトリ | `https://github.com/0ht/OCR-Demo` | 現在のGit remoteは `https://github.com/torimonn/AzurePoC`。remoteは変更していない |
| アプリ名称・機能 | OCR-Demo、PDF・画像のOCR | 添付ZIPはAI業務アシストで、決算書・参考資料から事業性評価Excelを作る機能と音声議事録を含む。画面モックとして分離 |
| 文書の版 | 内部表記1.0、2026-07-18 | 以前のv2.0資料より古く見えるため、履歴を削除せず本資料を最新引継ぎ基準として併記 |
| Azure実環境 | 適用状況は要確認 | `apply` は行わず、コードとplanを検証する |
| State | 存在有無は要確認 | 既存stateを確認するまでresource addressを不用意に変更しない |

## 次に人が確認すること

1. 正式なGitHubリポジトリが `0ht/OCR-Demo` と `torimonn/AzurePoC` のどちらか
2. 正式な案件名がOCR-DemoとAI業務アシストのどちらか、または基盤名と画面名を分けるか
3. Azure上に既存リソースと既存stateがあるか
4. Hub接続、DNS、Firewall、管理VMへのSSH経路が準備済みか
5. アプリの音声議事録機能が正式な対象範囲か

この5点が確定するまでは、Azureリソース名、state key、Git remoteを一括変更しません。

## 今回の検証結果

| 確認 | 結果 |
|---|---|
| Terraform CLI | 公式配布の1.15.8をSHA256照合して使用 |
| `terraform fmt -check -recursive` | 成功 |
| bootstrap `terraform validate` | 成功 |
| bootstrap確認plan | `5 add / 0 change / 0 destroy` |
| solution `terraform validate` | 成功。採用AVM内のdeprecated warningのみ |
| solution確認plan | 構成評価で `20 add / 0 change / 0 destroy` を表示。ダミーSubscriptionはAzure CLIで認証できないため最終終了コードは失敗 |
| Python依存関係 | Streamlit 1.59.2、openpyxl 3.1.5、`pip check` 成功 |
| Python単体テスト | 5件成功 |
| ブラウザー確認 | 390px幅でログイン、資料抽出、音声議事録生成を確認。console error 0件 |
| Docker build | Docker CLIは存在するがDocker Desktop engine停止中のため未実施 |

Azure実環境の正式なplanでは、実Subscriptionへログインした状態で `terraform.tfvars` とbackendを設定し直してください。今回は `terraform apply` を実行していません。
