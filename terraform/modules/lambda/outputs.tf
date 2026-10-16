############################################
# LAMBDA OUTPUTS
############################################

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.app.function_name
}

output "lambda_alias" {
  description = "Name of the Lambda function alias (live)"
  value       = aws_lambda_alias.live.name
}

output "lambda_alias_live_invoke_arn" {
  description = "Invoke ARN of the live Lambda alias, used to integrate it with API Gateway"
  value       = aws_lambda_alias.live.invoke_arn
}

output "log_group_lambda_name" {
  description = "Name of the CloudWatch log group used by the Lambda function"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "lambda_artifacts_bucket_name" {
  description = "Name of the S3 bucket that stores Lambda deployment packages"
  value       = aws_s3_bucket.lambda_artifacts.id
}

output "lambda_artifacts_bucket_arn" {
  description = "ARN of the Lambda artifacts bucket (use in the GitHub OIDC role policy)"
  value       = aws_s3_bucket.lambda_artifacts.arn
}
