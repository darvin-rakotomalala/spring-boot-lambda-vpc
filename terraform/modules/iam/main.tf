############################################
# IAM
############################################

# IAM role for Terraform execution (used in CI/CD via GitHub Actions OIDC)

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "terraform_execution" {
  name = "${var.naming_prefix}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}*/${var.github_repo}*:*"
          }
        }
      }
    ]
  })

  # Maximum session duration (1 hour for Terraform runs)
  max_session_duration = 3600

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-ga-oidc"
  })
}

resource "aws_iam_role_policy_attachment" "terraform_execution_admin" {
  role       = aws_iam_role.terraform_execution.name
  policy_arn = "arn:${var.current_partition}:iam::aws:policy/AdministratorAccess" # TODO: scope down before production use
}

### --------------------------------------------------------------------------
# RDS Monitoring
data "aws_iam_policy_document" "rds_monitoring_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name               = "${var.naming_prefix}-rds-enhanced-monitoring"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_trust.json
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:${var.current_partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

### --------------------------------------------------------------------------

############################ RDS Proxy ############################
data "aws_iam_policy_document" "proxy_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "proxy_perms" {
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [var.db_master_user_secret_arn]
  }
  statement {
    actions   = ["kms:Decrypt"]
    resources = [var.kms_key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.primary_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "proxy" {
  name               = "${var.naming_prefix}-rds-proxy"
  assume_role_policy = data.aws_iam_policy_document.proxy_trust.json
}

resource "aws_iam_role_policy" "proxy" {
  name   = "${var.naming_prefix}-read-db-secret"
  role   = aws_iam_role.proxy.id
  policy = data.aws_iam_policy_document.proxy_perms.json
}

### --------------------------------------------------------------------------

locals {
  proxy_resource_id = element(split(":", var.rds_proxy_arn), 6) # prx-xxxx
  lambda_log_group  = "/aws/lambda/${var.naming_prefix}-log-group"
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.naming_prefix}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# ENI management + basic logs, as in the spec.
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:${var.current_partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "lambda_inline" {
  statement {
    sid       = "ReadDbSecret"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_master_user_secret_arn]
  }

  statement {
    sid       = "DecryptProjectKey"
    actions   = ["kms:Decrypt"]
    resources = [var.kms_key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "secretsmanager.${var.primary_region}.amazonaws.com",
        "lambda.${var.primary_region}.amazonaws.com",
      ]
    }
  }

  statement {
    sid       = "WriteOwnLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:${var.current_partition}:logs:${var.primary_region}:${var.current_account_id}:log-group:${local.lambda_log_group}:*"]
  }

  dynamic "statement" {
    for_each = var.proxy_iam_auth == "REQUIRED" ? [1] : []
    content {
      sid       = "ConnectToProxyAsDbUser"
      actions   = ["rds-db:connect"]
      resources = ["arn:${var.current_partition}:rds-db:${var.primary_region}:${var.current_account_id}:dbuser:${local.proxy_resource_id}/${var.db_username}"]
    }
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.naming_prefix}-least-privilege"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_inline.json
}
