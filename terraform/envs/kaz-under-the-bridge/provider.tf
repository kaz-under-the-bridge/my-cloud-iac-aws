terraform {
  # renovate: datasource=github-releases depName=hashicorp/terraform
  required_version = "1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.97.0"
    }
  }

  # S3バックエンドの設定
  backend "s3" {
    bucket       = "kaz-under-the-bridge-terraform-state"
    key          = "terraform/kaz-under-the-bridge/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true
  }
}

# AWSプロバイダーの設定
provider "aws" {
  region = "ap-northeast-1" # 東京リージョン

  # デフォルトタグ設定（任意）
  default_tags {
    tags = {
      Environment = "sandbox"
      Terraform   = "true"
      Project     = "my-cloud-iac-aws"
    }
  }
}
