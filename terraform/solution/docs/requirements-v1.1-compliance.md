# 要件整理書v1.1 照合結果

確認日: 2026-07-18

対象: `OCR-Demo_Azure閉域基盤_現時点要件整理書_v1.1.docx`

## 現行フェーズで実装済み

| 要件 | 実装状況 |
|---|---|
| bootstrapとsolutionの2 root module | 実装済み |
| State用Resource Group、Storage Account、tfstate Container、実行者RBAC | bootstrapで実装済み |
| State Storageの初期Public到達とMicrosoft Entra ID認証 | Public Network Access有効、Shared Key無効、AzAPIによるEntra ID認証で実装済み |
| Spoke VNet `10.30.0.0/24` と3 Subnet | 実装済み |
| ACA `10.30.0.0/25` | delegation付きで実装済み |
| Private Endpoint `10.30.0.128/26` | Network Policy無効、UDRなしで実装済み |
| 管理VM `10.30.0.192/28`、固定IP `10.30.0.196` | 実装済み |
| 管理VMのPublic IPなし | 実装済み |
| 管理VMのMicrosoft Entra ID SSH | System Assigned IdentityとAADSSHLoginForLinuxで実装済み |
| Hub BastionからのSSH制限 | CIDR指定時だけTCP/22許可ルールを作成 |
| AI系3Zone、Blob、Key VaultのPrivate DNS Zone | 5ZoneとSpoke VNet Linkを実装済み |
| Azure AI、アプリ用Storage、Key VaultのPrivate Endpoint | 対象リソースAVMで実装済み |
| PaaSのPublic Network Access無効 | AI、アプリ用Storage、Key Vaultで実装済み |
| Blob ContainerとKey Vault Secretを初期作成しない | 実装済み |
| 初期UDR無効、PE SubnetへUDRを付けない | 実装済み |
| State Storageの段階的Private化 | solutionの任意State Storage PEとbootstrapのネットワーク変数で実装済み |
| Provider・AVM固定とlock file管理 | 実装済み |
| 実tfvars、backend、state、plan、Secret、秘密鍵をGit管理しない | `.gitignore`で除外 |

## 後続フェーズで実装するもの

- Hub-Spoke Peering、ExpressRoute、Hub Firewall、DNS Private Resolver
- ACR、Azure Container Apps Environment、UI/API Container App
- User Assigned Managed Identityとアプリ用RBAC
- アプリ用Blob Containerとデータプレーン疎通
- Dify専用Subnet、Public IPなしLinux VM、Docker Compose
- 監視、バックアップ、復旧、運用手順

これらは要件書で後続フェーズまたは共通基盤側の対象とされているため、現行の初期solutionには作成resourceを追加していません。

## 適用前に確定が必要な項目

- Azure Bastionの配置、SKU、利用期間、Spokeへの到達経路
- 管理VMログインRoleを付与するMicrosoft Entraユーザーまたはグループ
- Hub Firewall Private IP、許可先、戻り経路
- 2026年3月31日以降のPrivate Subnet既定化を踏まえた、管理VMの明示的な外向き経路
- オンプレDNSとPrivate DNSの連携方式
- Azure上の既存resourceと既存stateの有無

AADSSHLoginForLinuxの導入には、System Assigned Managed Identityに加えて必要な外向き通信が必要です。Public IPやNAT Gatewayはこのsolutionで追加せず、Hub Firewall等の共通基盤設計で扱います。
