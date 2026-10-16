############################################
# RDS
############################################

locals {
  db_secret_arn  = aws_db_instance.this.master_user_secret[0].secret_arn
  db_port        = 5432
  db_log_exports = ["postgresql", "upgrade"]

  # Protect production data; keep non-prod easy to tear down.
  is_production       = var.environment == "prod"
  deletion_protection = local.is_production
  skip_final_snapshot = !local.is_production
}

# Pre-create DB log groups so they are encrypted with our CMK.
resource "aws_cloudwatch_log_group" "db" {
  for_each          = toset(local.db_log_exports)
  name              = "/aws/rds/instance/${var.naming_prefix}-pg/${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-log-group"
  })
}

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.naming_prefix}-db-parameter-group"
  family      = var.db_parameter_group_family

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
  parameter {
    name  = "log_connections"
    value = "1"
  }
  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.naming_prefix}-rds-pg"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # Storage: encrypted with the CMK, grows automatically (dynamic scaling).
  storage_type          = "gp3"
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_name  = var.db_name
  username = var.db_username
  port     = local.db_port

  # RDS creates + rotates the master secret in Secrets Manager (encrypted with our CMK).
  # The password never exists in Terraform code or state.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  iam_database_authentication_enabled = true

  # Network
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [var.database_security_group_id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az
  availability_zone      = var.db_multi_az ? null : var.availability_zones[0]
  parameter_group_name   = aws_db_parameter_group.this.name

  # Resilience / ops
  backup_retention_period    = var.db_backup_retention_days
  backup_window              = "03:00-04:00"
  maintenance_window         = "sun:04:30-sun:05:30"
  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true
  deletion_protection        = local.deletion_protection
  skip_final_snapshot        = local.skip_final_snapshot
  final_snapshot_identifier  = local.skip_final_snapshot ? null : "${var.naming_prefix}-pg-final"
  apply_immediately          = false

  # Observability
  enabled_cloudwatch_logs_exports       = local.db_log_exports
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_key_arn
  performance_insights_retention_period = 7
  monitoring_interval                   = 60
  monitoring_role_arn                   = var.rds_enhanced_monitoring_role_arn

  depends_on = [aws_cloudwatch_log_group.db]

  lifecycle {
    ignore_changes = [engine_version] # minor upgrades happen automatically
  }

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-pg"
  })
}

resource "aws_db_proxy" "this" {
  name                   = "${var.naming_prefix}-rds-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = var.rds_proxy_role_arn
  vpc_subnet_ids         = var.private_subnet_ids
  vpc_security_group_ids = [var.rds_proxy_security_group_id]
  require_tls            = true
  idle_client_timeout    = 1800
  debug_logging          = false

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = var.db_credentials_secret_arn
    iam_auth    = var.proxy_iam_auth
    description = "Master credentials (RDS-managed secret)"
  }

  # The proxy must reach Secrets Manager through the endpoint.
  depends_on = [var.interface_endpoint, var.rds_proxy_policy_name]

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-rds-proxy"
  })
}

resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    max_connections_percent      = var.proxy_max_connections_percent
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 30
  }
}

resource "aws_db_proxy_target" "this" {
  db_proxy_name          = aws_db_proxy.this.name
  target_group_name      = aws_db_proxy_default_target_group.this.name
  db_instance_identifier = aws_db_instance.this.identifier
}
