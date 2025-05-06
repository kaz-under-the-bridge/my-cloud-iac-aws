locals {
  s3_buckets = [
    {
      name = "kaz-under-the-bridge-terraform-state"
      tags = {
        Name        = "terraform-state"
        Environment = "sandbox"
        Purpose     = "terraform-state-storage"
      }
      versioning             = true
      server_side_encryption = "AES256"
      public_access_block    = true
      #
      public_access_block_config = {
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
      }
    }
  ]
}

# S3バケットを作成
resource "aws_s3_bucket" "main" {
  for_each = { for bucket in local.s3_buckets : bucket.name => bucket }

  bucket = each.value.name

  lifecycle {
    prevent_destroy = true
  }

  tags = each.value.tags
}

# バージョニング設定
resource "aws_s3_bucket_versioning" "main" {
  for_each = { for bucket in local.s3_buckets : bucket.name => bucket if bucket.versioning }

  bucket = aws_s3_bucket.main[each.key].id

  versioning_configuration {
    # versioning = trueであればstatusをEnabledにする
    status = each.value.versioning ? "Enabled" : "Disabled"
  }
}

# サーバーサイド暗号化の設定
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = { for bucket in local.s3_buckets : bucket.name => bucket if bucket.server_side_encryption != null }

  bucket = aws_s3_bucket.main[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = each.value.server_side_encryption
    }
  }
}

# パブリックアクセスをブロック
resource "aws_s3_bucket_public_access_block" "main" {
  for_each = { for bucket in local.s3_buckets : bucket.name => bucket if bucket.public_access_block }

  bucket = aws_s3_bucket.main[each.key].id

  block_public_acls       = each.value.public_access_block_config.block_public_acls
  block_public_policy     = each.value.public_access_block_config.block_public_policy
  ignore_public_acls      = each.value.public_access_block_config.ignore_public_acls
  restrict_public_buckets = each.value.public_access_block_config.restrict_public_buckets
}
