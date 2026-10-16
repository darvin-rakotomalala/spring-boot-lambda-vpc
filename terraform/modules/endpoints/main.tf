############################################
# VPC ENDPOINTS
############################################

############################ Gateway endpoints (free) ############################
resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(["s3", "dynamodb"])

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.primary_region}.${each.key}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = { Name = "${var.naming_prefix}-${each.key}-gw" }
}

############################ Interface endpoints ############################
# Lock the Secrets Manager endpoint to: this account's principals, read actions, the DB secret only.
data "aws_iam_policy_document" "secretsmanager_endpoint" {
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [var.db_credentials_secret_arn]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [var.current_account_id]
    }
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(var.interface_endpoint_services)

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.primary_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.endpoints_security_group_id]
  private_dns_enabled = true
  policy              = each.key == "secretsmanager" ? data.aws_iam_policy_document.secretsmanager_endpoint.json : null

  tags = { Name = "${var.naming_prefix}-${each.key}-if" }
}
