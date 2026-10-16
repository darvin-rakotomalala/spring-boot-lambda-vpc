#########################################################
## VPC
#########################################################

module "vpc" {
  source                      = "./modules/vpc"
  common_tags                 = local.common_tags
  naming_prefix               = local.naming_prefix
  availability_zones          = var.availability_zones
  current_account_id          = data.aws_caller_identity.current.account_id
  interface_endpoint_services = var.interface_endpoint_services
  kms_key_arn                 = module.kms.kms_key_arn
  log_retention_days          = var.log_retention_days
  subnet_newbits              = var.subnet_newbits
  vpc_cidr                    = var.vpc_cidr
}

#########################################################
## SECURITY GROUPS
#########################################################

module "sg" {
  source        = "./modules/sg"
  common_tags   = local.common_tags
  naming_prefix = local.naming_prefix
  vpc_id        = module.vpc.vpc_id
}

#########################################################
## VPC ENDPOINT
#########################################################

module "endpoints" {
  source                      = "./modules/endpoints"
  common_tags                 = local.common_tags
  naming_prefix               = local.naming_prefix
  current_account_id          = data.aws_caller_identity.current.account_id
  db_credentials_secret_arn   = module.secrets.db_credentials_secret_arn
  endpoints_security_group_id = module.sg.endpoints_security_group_id
  interface_endpoint_services = var.interface_endpoint_services
  primary_region              = var.primary_region
  private_route_table_ids     = values(module.vpc.private_route_table_ids)
  private_subnet_ids          = module.vpc.private_subnet_ids
  vpc_id                      = module.vpc.vpc_id
}

#########################################################
## IAM
#########################################################

module "iam" {
  source                    = "./modules/iam"
  current_account_id        = data.aws_caller_identity.current.account_id
  naming_prefix             = local.naming_prefix
  common_tags               = local.common_tags
  github_org                = var.github_org
  github_repo               = var.github_repo
  current_partition         = data.aws_partition.current.partition
  db_master_user_secret_arn = module.secrets.db_credentials_secret_arn
  db_username               = var.db_username
  kms_key_arn               = module.kms.kms_key_arn
  primary_region            = var.primary_region
  proxy_iam_auth            = var.proxy_iam_auth
  rds_proxy_arn             = module.rds.rds_proxy_arn
}

#########################################################
## LAMBDA
#########################################################

module "lambda" {
  source                           = "./modules/lambda"
  naming_prefix                    = local.naming_prefix
  common_tags                      = local.common_tags
  log_group_lambda_name            = module.iam.cloudwatch_log_group_lambda
  db_name                          = var.db_name
  db_proxy_target_arn              = module.rds.db_proxy_target_arn
  db_username                      = var.db_username
  environment                      = var.environment
  interface_endpoint               = module.endpoints.interface_endpoint["secretsmanager"]
  kms_key_arn                      = module.kms.kms_key_arn
  lambda_architecture              = var.lambda_architecture
  lambda_environment               = var.lambda_environment
  lambda_handler                   = var.lambda_handler
  lambda_iam_role_arn              = module.iam.lambda_iam_role_arn
  lambda_inline_policy_name        = module.iam.lambda_inline_policy_name
  lambda_memory_mb                 = var.lambda_memory_mb
  lambda_reserved_concurrency      = var.lambda_reserved_concurrency
  lambda_security_group_id         = module.sg.lambda_security_group_id
  lambda_timeout_s                 = var.lambda_timeout_s
  lambda_vpc_access_policy_arn     = module.iam.lambda_vpc_access_policy_arn
  latency_strategy                 = var.latency_strategy
  log_retention_days               = var.log_retention_days
  pc_max_capacity                  = var.pc_max_capacity
  pc_min_capacity                  = var.pc_min_capacity
  pc_target_utilization            = var.pc_target_utilization
  private_subnet_ids               = module.vpc.private_subnet_ids
  proxy_iam_auth                   = var.proxy_iam_auth
  random_password_db_master_result = module.secrets.random_password_db_master_result
  rds_db_port                      = module.rds.rds_db_port
  rds_proxy_endpoint               = module.rds.rds_proxy_endpoint
}

#########################################################
## API GATEWAY
#########################################################

module "api-gateway" {
  source                       = "./modules/api-gateway"
  naming_prefix                = local.naming_prefix
  common_tags                  = local.common_tags
  api_authorization            = var.api_authorization
  api_throttle_burst           = var.api_throttle_burst
  api_throttle_rate            = var.api_throttle_rate
  create_apigw_account_role    = var.create_apigw_account_role
  current_partition            = data.aws_partition.current.partition
  environment                  = var.environment
  kms_key_arn                  = module.kms.kms_key_arn
  lambda_alias                 = module.lambda.lambda_alias
  lambda_alias_live_invoke_arn = module.lambda.lambda_alias_live_invoke_arn
  lambda_function_name         = module.lambda.lambda_function_name
  log_retention_days           = var.log_retention_days
}

#########################################################
## RDS
#########################################################

module "rds" {
  source                           = "./modules/rds"
  naming_prefix                    = local.naming_prefix
  common_tags                      = local.common_tags
  availability_zones               = var.availability_zones
  database_security_group_id       = module.sg.database_security_group_id
  db_allocated_storage             = var.db_allocated_storage
  db_backup_retention_days         = var.db_backup_retention_days
  db_engine_version                = var.db_engine_version
  db_instance_class                = var.db_instance_class
  db_max_allocated_storage         = var.db_max_allocated_storage
  db_multi_az                      = var.db_multi_az
  db_name                          = var.db_name
  db_parameter_group_family        = var.db_parameter_group_family
  db_subnet_group_name             = module.vpc.db_subnet_group_name
  db_username                      = var.db_username
  environment                      = var.environment
  interface_endpoint               = module.endpoints.interface_endpoint["secretsmanager"]
  kms_key_arn                      = module.kms.kms_key_arn
  log_retention_days               = var.log_retention_days
  private_subnet_ids               = module.vpc.private_subnet_ids
  proxy_iam_auth                   = var.proxy_iam_auth
  proxy_max_connections_percent    = var.proxy_max_connections_percent
  rds_enhanced_monitoring_role_arn = module.iam.rds_enhanced_monitoring_role_arn
  rds_proxy_policy_name            = module.iam.rds_proxy_policy_name
  rds_proxy_role_arn               = module.iam.rds_proxy_role_arn
  rds_proxy_security_group_id      = module.sg.rds_proxy_security_group_id
  db_credentials_secret_arn        = module.secrets.db_credentials_secret_arn
}

#########################################################
## KMS
#########################################################

module "kms" {
  source              = "./modules/kms"
  naming_prefix       = local.naming_prefix
  common_tags         = local.common_tags
  current_account_id  = data.aws_caller_identity.current.account_id
  current_partition   = data.aws_partition.current.partition
  primary_region      = var.primary_region
  lambda_iam_role_arn = module.iam.lambda_iam_role_arn
}

#########################################################
## SECRETS MANAGER
#########################################################

module "secrets" {
  source              = "./modules/secrets"
  naming_prefix       = local.naming_prefix
  common_tags         = local.common_tags
  db_name             = var.db_name
  db_username         = var.db_username
  rds_address         = module.rds.rds_address
  rds_port            = module.rds.rds_port
  kms_secrets_key_arn = module.kms.kms_secrets_key_arn
}

#########################################################
## SNS
#########################################################

module "sns" {
  source        = "./modules/sns"
  naming_prefix = local.naming_prefix
  common_tags   = local.common_tags
  alarm_email   = var.alarm_email
  kms_key_arn   = module.kms.kms_key_arn
}

#########################################################
## CLOUDWATCH
#########################################################

module "cloudwatch" {
  source                    = "./modules/cloudwatch"
  naming_prefix             = local.naming_prefix
  common_tags               = local.common_tags
  alarm_topic_arn           = module.sns.alarm_topic_arn
  api_4xx_threshold         = var.api_4xx_threshold
  api_5xx_threshold         = var.api_5xx_threshold
  api_gateway_rest_api_name = module.api-gateway.api_gateway_rest_api_name
  api_gateway_stage_name    = module.api-gateway.api_gateway_stage_name
  lambda_function_name      = module.lambda.lambda_function_name
  min_success_rate_percent  = var.min_success_rate_percent
  log_group_lambda_name     = module.lambda.log_group_lambda_name
}
