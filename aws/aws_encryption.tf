# ============================================================
# AWS KMS - Customer Managed Keys for Encryption
# ============================================================

# KMS Key for S3 / EBS / General Use
resource "aws_kms_key" "secure_key" {
  description             = "CMK for Secure MultiCloud Project"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name    = "${var.project_name}-kms-key"
    Project = var.project_name
  }
}

resource "aws_kms_alias" "secure_key_alias" {
  name          = "alias/${var.project_name}-key"
  target_key_id = aws_kms_key.secure_key.key_id
}

# ============================================================
# S3 Bucket - Server-Side Encryption with KMS
# ============================================================

resource "aws_s3_bucket" "secure_data" {
  bucket = "${var.project_name}-secure-data-2026"

  tags = {
    Name    = "${var.project_name}-secure-data"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_data_sse" {
  bucket = aws_s3_bucket.secure_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.secure_key.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "secure_data_versioning" {
  bucket = aws_s3_bucket.secure_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "secure_data_block" {
  bucket = aws_s3_bucket.secure_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================
# KMS Policy - Restrict access
# ============================================================

resource "aws_kms_key_policy" "secure_key_policy" {
  key_id = aws_kms_key.secure_key.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EC2 Role"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2_role.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================
# EBS Encryption by Default
# ============================================================

resource "aws_ebs_encryption_by_default" "enabled" {
  enabled = true
}

resource "aws_ebs_default_kms_key" "project_key" {
  key_arn = aws_kms_key.secure_key.arn
}

# ============================================================
# Outputs
# ============================================================

output "kms_key_id" {
  value       = aws_kms_key.secure_key.key_id
  description = "KMS Key ID"
}

output "kms_key_arn" {
  value       = aws_kms_key.secure_key.arn
  description = "KMS Key ARN"
}

output "secure_s3_bucket" {
  value       = aws_s3_bucket.secure_data.bucket
  description = "Encrypted S3 Bucket Name"
}
