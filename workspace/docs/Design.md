# my-cloud-iac-aws プロジェクト設計ドキュメント

## 目次

1. [プロジェクト概要](#プロジェクト概要)
2. [インフラストラクチャ設計](#インフラストラクチャ設計)
   - [VPC設計](#vpc設計)
   - [S3バケット設計](#s3バケット設計)
   - [OIDC認証設計](#oidc認証設計)
   - [Route53設定](#route53設定)
3. [CI/CDパイプライン](#cicdパイプライン)
   - [GitHub Actionsワークフロー](#github-actionsワークフロー)
   - [tfaction設定](#tfaction設定)
4. [ツールとライブラリ](#ツールとライブラリ)
5. [運用上の考慮事項](#運用上の考慮事項)

## プロジェクト概要

このプロジェクトは、AWSインフラストラクチャをコードとして管理するためのTerraformベースのIaC（Infrastructure as Code）リポジトリです。主な目的は以下の通りです：

- AWSリソースをコードとして定義・管理
- CI/CDパイプラインを通じた安全かつ効率的なインフラ変更の適用
- 個人用サンドボックス環境としての利用

プロジェクトは、Terraformモジュールとワークフローの組み合わせにより、インフラストラクチャの一貫性と再現性を確保しています。

## インフラストラクチャ設計

### VPC設計

VPCは3層アーキテクチャ（パブリック/プロテクテッド/プライベート）で設計されています。コスト管理のため、デフォルトでは無効化されています（`enabled = false`）。

#### 主要コンポーネント

- **VPC**: CIDR `10.0.0.0/16`、DNS設定有効
- **サブネット構成**:
  - パブリックサブネット (2つ): `10.0.0.0/24` (ap-northeast-1a), `10.0.1.0/24` (ap-northeast-1c)
  - プロテクテッドサブネット (2つ): `10.0.10.0/24` (ap-northeast-1a), `10.0.11.0/24` (ap-northeast-1c)
  - プライベートサブネット (2つ): `10.0.20.0/24` (ap-northeast-1a), `10.0.21.0/24` (ap-northeast-1c)

#### ネットワークコンポーネント

- **インターネットゲートウェイ**: パブリックサブネットからインターネットへの接続
- **NATゲートウェイ** (2つ): プロテクテッドサブネットからインターネットへの接続
- **ルートテーブル**:
  - パブリック: インターネットゲートウェイ経由でインターネットアクセス
  - プロテクテッド: NATゲートウェイ経由でインターネットアクセス
  - プライベート: インターネットアクセスなし

#### VPCエンドポイント

- **S3エンドポイント**: プロテクテッドサブネットからS3へのプライベートアクセス
- **VPCモジュール**: 追加のVPCエンドポイント（ECR、SSM、CloudWatchなど）を提供

#### セキュリティ設定

- **VPCフローログ**: CloudWatchに7日間保存
- **IAMロール**: フローログ用の専用ロールとポリシー

### S3バケット設計

Terraformの状態管理用のS3バケットが定義されています。

#### 主要設定

- **バケット名**: `kaz-under-the-bridge-terraform-state`
- **バージョニング**: 有効
- **暗号化**: AES256によるサーバーサイド暗号化
- **パブリックアクセス**: 完全にブロック
- **ライフサイクル管理**: `prevent_destroy = true`で誤削除を防止

### OIDC認証設計

GitHub ActionsからAWSリソースへの安全なアクセスを提供するためのOIDC認証が設定されています。

#### 主要コンポーネント

- **OIDCプロバイダー**: GitHub Actionsのトークン発行者
- **IAMロール**:
  - `terraform_apply`: 管理者アクセス権限
  - `terraform_plan`: 読み取り専用アクセス権限
  - `tfmigrate_plan`: 読み取り専用アクセス権限
  - `tfmigrate_apply`: 読み取り専用アクセス権限

#### 外部モジュール

- `suzuki-shunsuke/terraform-aws-tfaction`: OIDC認証とIAMロール設定の簡素化

### Route53設定

プロジェクト用のDNSゾーンが設定されています。

- **ゾーン名**: `aws.under-the-bridge.work`
- **用途**: AWSリソース用のサブドメイン

## CI/CDパイプライン

### GitHub Actionsワークフロー

#### terraform-plan ワークフロー

プルリクエスト時に実行され、Terraformの変更計画を生成します。

- **トリガー**: プルリクエスト（`main`ブランチ向け）
- **対象パス**: `terraform/envs/**`, `terraform/modules/**`
- **主要ステップ**:
  1. 変更のある作業ディレクトリの特定
  2. 並列実行による効率化
  3. GitHub Appトークンの取得
  4. Terraformの初期化と計画実行
  5. 計画結果のPRコメント投稿

#### terraform-apply ワークフロー

`main`ブランチへのプッシュ時に実行され、Terraformの変更を適用します。

- **トリガー**: `main`ブランチへのプッシュ
- **対象パス**: `terraform/envs/**`, `terraform/modules/**`
- **主要ステップ**:
  1. 変更のある作業ディレクトリの特定
  2. 並列実行による効率化
  3. GitHub Appトークンの取得
  4. Terraformの初期化と適用実行
  5. 適用結果のPRコメント投稿

#### lint ワークフロー

YAMLファイルの構文チェックとGitHub Actionsワークフローの検証を行います。

- **トリガー**: プルリクエスト（YAMLファイル変更時）
- **主要ステップ**:
  1. yamllintによるYAMLファイルの検証
  2. actionlintによるGitHub Actionsワークフローの検証

### tfaction設定

`tfaction-root.yaml`ファイルでCI/CDパイプラインの設定を定義しています。

#### 主要設定

- **ワークフロー名**: `terraform-plan`
- **作業ディレクトリ**: `terraform/envs/kaz-under-the-bridge`
- **AWSリージョン**: `ap-northeast-1`
- **S3バケット**:
  - 計画ファイル: `kaz-under-the-bridge-terraform-state`
  - tfmigrate履歴: `kaz-under-the-bridge-terraform-state`
- **IAMロール**:
  - terraform_plan: `arn:aws:iam::905418419021:role/GitHubActions_Terraform_AWS_terraform_plan`
  - tfmigrate_plan: `arn:aws:iam::905418419021:role/GitHubActions_Terraform_AWS_tfmigrate_plan`
  - terraform_apply: `arn:aws:iam::905418419021:role/GitHubActions_Terraform_AWS_terraform_apply`
  - tfmigrate_apply: `arn:aws:iam::905418419021:role/GitHubActions_Terraform_AWS_tfmigrate_apply`

## ツールとライブラリ

プロジェクトで使用される主要なツールとライブラリは以下の通りです：

### aqua

`aqua.yaml`ファイルで定義されたパッケージ管理ツールで、以下のツールをバージョン管理しています：

- **Terraform**: v1.11.4
- **GitHub CLI**: v2.60.1
- **tfmigrate**: v0.3.24
- **tfcmt**: v4.14.0
- **terraform-docs**: v0.19.0
- **actionlint**: v1.7.3
- **tflint**: v0.53.0
- **trivy**: v0.57.0

### tfaction

suzuki-shunsuke/tfactionは、TerraformのCI/CD自動化を簡素化するためのGitHub Actionsです。主な機能：

- 変更のある作業ディレクトリの自動検出
- Terraform計画と適用の自動化
- PRコメントによるフィードバック
- 並列実行によるパフォーマンス向上

## 運用上の考慮事項

### コスト管理

- **VPCリソース**: デフォルトで無効化（`enabled = false`）されており、必要な時のみ有効化することでコストを抑制
- **NATゲートウェイ**: コスト発生要素であるため、デフォルトでは作成されない

### 状態管理

- **S3バケット**: Terraformの状態ファイルを安全に保存
- **バージョニング**: 状態ファイルの変更履歴を保持
- **暗号化**: セキュリティ強化のためのサーバーサイド暗号化

### セキュリティ

- **OIDC認証**: GitHub ActionsからAWSへの安全なアクセス
- **最小権限の原則**: 各ワークフローに必要最小限の権限を付与
- **パブリックアクセスブロック**: S3バケットへの不正アクセスを防止

### CI/CD自動化

- **変更検出**: 変更のあるディレクトリのみを対象に実行
- **並列実行**: 複数の作業ディレクトリを同時に処理
- **フィードバック**: PRコメントによる変更内容の可視化
