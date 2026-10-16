############################################
# IAM OUTPUTS
############################################

output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  value       = aws_iam_role.terraform_execution.arn
}

output "rds_proxy_role_arn" {
  description = "ARN of the IAM role assumed by the RDS Proxy to read the database secret"
  value       = aws_iam_role.proxy.arn
}

output "rds_proxy_role_name" {
  description = "Name of the IAM role assumed by the RDS Proxy"
  value       = aws_iam_role.proxy.name
}

output "rds_proxy_policy_name" {
  description = "Name of the inline IAM policy granting the RDS Proxy role access to the database secret"
  value       = aws_iam_role_policy.proxy.name
}

output "rds_proxy_policy_id" {
  description = "ID of the inline IAM policy attached to the RDS Proxy role (format: role_name:policy_name)"
  value       = aws_iam_role_policy.proxy.id
}

output "cloudwatch_log_group_lambda" {
  description = "Name of the CloudWatch log group used by the Lambda function"
  value       = local.lambda_log_group
}

output "lambda_iam_role_arn" {
  description = "ARN of the IAM role assumed by the Lambda function"
  value       = aws_iam_role.lambda.arn
}

output "lambda_vpc_access_policy_arn" {
  description = "ARN of the managed policy (AWSLambdaVPCAccessExecutionRole) attached to the Lambda role for VPC and ENI access"
  value       = aws_iam_role_policy_attachment.lambda_vpc.policy_arn
}

output "lambda_inline_policy_name" {
  description = "Name of the inline IAM policy attached to the Lambda role"
  value       = aws_iam_role_policy.lambda.name
}

output "rds_enhanced_monitoring_role_arn" {
  description = "ARN of the IAM role used by RDS Enhanced Monitoring"
  value       = aws_iam_role.rds_monitoring.arn
}
