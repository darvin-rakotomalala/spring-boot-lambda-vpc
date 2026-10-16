############################################
# SG
############################################

# All rules are separate resources and reference SGs, never CIDRs.
# Terraform strips AWS's default allow-all egress, so anything not listed is denied.

resource "aws_security_group" "lambda" {
  name        = "${var.naming_prefix}-LambdaSG"
  description = "Lambda function ENIs (no inbound)"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-lambda-sg"
  })

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "endpoints" {
  name        = "${var.naming_prefix}-SecretsManagerSG"
  description = "Interface VPC endpoints"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-SecretsManager-sg"
  })

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "rds_proxy" {
  name        = "${var.naming_prefix}-RdsProxySG"
  description = "RDS Proxy"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-RdsProxy-sg"
  })

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "database" {
  name        = "${var.naming_prefix}-database-sg"
  description = "RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-database-sg"
  })

  lifecycle { create_before_destroy = true }
}

# --- Lambda egress ---
resource "aws_vpc_security_group_egress_rule" "lambda_to_endpoints" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.endpoints.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS to VPC interface endpoints"
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_proxy" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.rds_proxy.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL to RDS Proxy"
}

# --- Endpoints ingress (Lambda + RDS Proxy both call Secrets Manager) ---
resource "aws_vpc_security_group_ingress_rule" "endpoints_from_lambda" {
  security_group_id            = aws_security_group.endpoints.id
  referenced_security_group_id = aws_security_group.lambda.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS from Lambda"
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_proxy" {
  security_group_id            = aws_security_group.endpoints.id
  referenced_security_group_id = aws_security_group.rds_proxy.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS from RDS Proxy (reads the DB secret)"
}

# --- RDS Proxy ---
resource "aws_vpc_security_group_ingress_rule" "proxy_from_lambda" {
  security_group_id            = aws_security_group.rds_proxy.id
  referenced_security_group_id = aws_security_group.lambda.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL from Lambda"
}

resource "aws_vpc_security_group_egress_rule" "proxy_to_db" {
  security_group_id            = aws_security_group.rds_proxy.id
  referenced_security_group_id = aws_security_group.database.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL to database"
}

resource "aws_vpc_security_group_egress_rule" "proxy_to_endpoints" {
  security_group_id            = aws_security_group.rds_proxy.id
  referenced_security_group_id = aws_security_group.endpoints.id
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  description                  = "HTTPS to Secrets Manager endpoint"
}

# --- Database ---
resource "aws_vpc_security_group_ingress_rule" "db_from_proxy" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.rds_proxy.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL from RDS Proxy only"
}
