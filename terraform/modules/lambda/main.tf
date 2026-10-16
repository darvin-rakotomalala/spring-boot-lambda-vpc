############################################
# LAMBDA
############################################

## Lambda artifacts bucket
resource "aws_s3_bucket" "lambda_artifacts" {
  bucket_prefix = "${var.naming_prefix}-lambda-artifacts-69127"
  force_destroy = true
  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-lambda-artifacts"
  })
}

resource "aws_s3_bucket_public_access_block" "lambda_artifacts" {
  bucket                  = aws_s3_bucket.lambda_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

## Lambda Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = var.log_group_lambda_name
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

locals {
  use_snapstart = var.latency_strategy == "snapstart"
  use_pc        = var.latency_strategy == "provisioned_concurrency"
}

############################################
# DUMMY ZIP FOR INITIAL TERRAFORM PROVISIONING (Java 21)
############################################

data "archive_file" "lambda_dummy" {
  type        = "zip"
  output_path = "${path.module}/dummy_lambda.zip"

  source {
    content  = "dummy"
    filename = "com/ce/StreamLambdaHandler.class"
  }
}

resource "aws_lambda_function" "app" {
  function_name = var.naming_prefix
  description   = "Spring Boot API (Java 21)"
  role          = var.lambda_iam_role_arn
  runtime       = "java21"
  handler       = var.lambda_handler
  architectures = [var.lambda_architecture]
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_s

  # Standard code deployment configuration for initial boot
  filename         = data.archive_file.lambda_dummy.output_path
  source_code_hash = data.archive_file.lambda_dummy.output_base64sha256
  publish          = true # SnapStart + aliases need published versions

  kms_key_arn                    = var.kms_key_arn # encrypts env vars at rest
  reserved_concurrent_executions = var.lambda_reserved_concurrency

  vpc_config {
    subnet_ids                  = var.private_subnet_ids
    security_group_ids          = [var.lambda_security_group_id]
    ipv6_allowed_for_dual_stack = false
  }

  # Only references, never the password itself.
  environment {
    variables = merge(
      {
        DB_SECRET_ARN = var.random_password_db_master_result
        DB_HOST       = var.rds_proxy_endpoint
        DB_PORT       = tostring(var.rds_db_port)
        DB_NAME       = var.db_name
        DB_USER       = var.db_username
        DB_IAM_AUTH   = tostring(var.proxy_iam_auth == "REQUIRED")
        # SPRING_PROFILES_ACTIVE = var.environment
        JAVA_TOOL_OPTIONS = "-XX:+TieredCompilation -XX:TieredStopAtLevel=1"
      },
      var.lambda_environment,
    )
  }

  snap_start {
    apply_on = local.use_snapstart ? "PublishedVersions" : "None"
  }

  logging_config {
    log_format            = "JSON"
    log_group             = aws_cloudwatch_log_group.lambda.name
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    var.lambda_vpc_access_policy_arn,
    var.lambda_inline_policy_name,
    var.db_proxy_target_arn,
    var.interface_endpoint,
    aws_s3_bucket.lambda_artifacts,
  ]

  lifecycle {
    # The src/ pipeline owns the code after the first deploy.
    ignore_changes = [filename, source_code_hash]
  }
}

# CI publishes a version on each deploy and moves this alias; Terraform must not fight it.
resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.app.function_name
  function_version = aws_lambda_function.app.version

  lifecycle {
    ignore_changes = [function_version]
  }
}

############################ Provisioned concurrency + autoscaling ############################
resource "aws_lambda_provisioned_concurrency_config" "live" {
  count = local.use_pc ? 1 : 0

  function_name                     = aws_lambda_function.app.function_name
  qualifier                         = aws_lambda_alias.live.name
  provisioned_concurrent_executions = var.pc_min_capacity

  lifecycle {
    ignore_changes = [provisioned_concurrent_executions] # Application Auto Scaling owns it
  }
}

resource "aws_appautoscaling_target" "pc" {
  count = local.use_pc ? 1 : 0

  service_namespace  = "lambda"
  scalable_dimension = "lambda:function:ProvisionedConcurrency"
  resource_id        = "function:${aws_lambda_function.app.function_name}:${aws_lambda_alias.live.name}"
  min_capacity       = var.pc_min_capacity
  max_capacity       = var.pc_max_capacity

  depends_on = [aws_lambda_provisioned_concurrency_config.live]
}

resource "aws_appautoscaling_policy" "pc" {
  count = local.use_pc ? 1 : 0

  name               = "${var.naming_prefix}-pc-utilization"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.pc[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.pc[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.pc[0].resource_id

  target_tracking_scaling_policy_configuration {
    target_value = var.pc_target_utilization
    predefined_metric_specification {
      predefined_metric_type = "LambdaProvisionedConcurrencyUtilization"
    }
  }
}
