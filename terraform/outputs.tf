############################################
# MAIN OUTPUTS
############################################

output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  value       = module.iam.iam_role_terraform_execution_arn
}

output "db_credentials_secret_name" {
  description = "Name of the Secrets Manager secret holding the RDS master credentials"
  value       = module.secrets.db_credentials_secret_name
}

output "rds_endpoint" {
  description = "Connection endpoint (host:port) for the RDS primary"
  value       = module.rds.rds_endpoint
}

output "rds_proxy_endpoint" {
  description = "Connection endpoint (hostname) of the RDS Proxy, to be used by the application instead of the database endpoint"
  value       = module.rds.rds_proxy_endpoint
}

output "rds_db_name" {
  description = "DB name of the RDS PostgreSQL"
  value       = var.db_name
}

output "lambda_artifacts_bucket_name" {
  description = "Set this as the ARTIFACT_BUCKET variable in the GitHub dev environment"
  value       = module.lambda.lambda_artifacts_bucket_name
}

output "api_invoke_url" {
  description = "Base invoke URL for the deployed API Gateway dev stage"
  value       = module.api-gateway.api_invoke_url
}

output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = module.lambda.lambda_function_name
}

output "lambda_alias" {
  description = "Name of the Lambda function alias (live)"
  value       = module.lambda.lambda_alias
}

output "lambda_alias_live_invoke_arn" {
  description = "Invoke ARN of the live Lambda alias, used to integrate it with API Gateway"
  value       = module.lambda.lambda_alias_live_invoke_arn
}
