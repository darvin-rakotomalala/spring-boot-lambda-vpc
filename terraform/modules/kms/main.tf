############################################
# KMS
############################################

data "aws_iam_policy_document" "kms" {
  # Keeps IAM policies effective (and avoids a locked-out key).
  statement {
    sid       = "EnableIAMPolicies"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${var.current_partition}:iam::${var.current_account_id}:root"]
    }
  }

  statement {
    sid = "CloudWatchLogs"
    actions = [
      "kms:Encrypt*", "kms:Decrypt*", "kms:ReEncrypt*",
      "kms:GenerateDataKey*", "kms:Describe*",
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.primary_region}.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:${var.current_partition}:logs:${var.primary_region}:${var.current_account_id}:log-group:*"]
    }
  }

  # Secrets Manager + RDS (+ Lambda env vars) may use the key on behalf of principals in THIS account only.
  statement {
    sid = "UseViaAwsServices"
    actions = [
      "kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*",
      "kms:GenerateDataKey*", "kms:DescribeKey",
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "secretsmanager.${var.primary_region}.amazonaws.com",
        "rds.${var.primary_region}.amazonaws.com",
        "lambda.${var.primary_region}.amazonaws.com",
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.current_account_id]
    }
  }

  statement {
    sid       = "GrantsForAwsResources"
    actions   = ["kms:CreateGrant", "kms:ListGrants", "kms:RevokeGrant"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [var.current_account_id]
    }
  }

  # CloudWatch alarms -> encrypted SNS topic
  statement {
    sid       = "CloudWatchAlarmsToSns"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${var.current_partition}:cloudwatch:${var.primary_region}:${var.current_account_id}:alarm:*"]
    }
  }
}

resource "aws_kms_key" "main" {
  description         = "${var.naming_prefix}: secrets, RDS storage, logs, Lambda env, SNS"
  enable_key_rotation = true
  # rotation_period_in_days = 90
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.naming_prefix}"
  target_key_id = aws_kms_key.main.key_id
}

# ---------- KMS key: Secrets Manager encryption ----------
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager (DB credentials) encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableIAMUserPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:${var.current_partition}:iam::${var.current_account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowSecretsManagerServiceUse"
        Effect    = "Allow"
        Principal = { Service = "secretsmanager.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.current_account_id
          }
        }
      },
      {
        # Required so RDS can create/manage the master-user secret on our behalf
        # when aws_db_instance.main.manage_master_user_password = true
        Sid       = "AllowRDSServiceUse"
        Effect    = "Allow"
        Principal = { Service = "rds.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.current_account_id
          }
        }
      },
      {
        Sid      = "AllowLambdaRoleDecryptViaSecretsManager"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:DescribeKey"]
        Resource = ["*"]
        Principal = {
          AWS = [var.lambda_iam_role_arn]
        }
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.primary_region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-secrets-kms-key"
  })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.naming_prefix}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}
