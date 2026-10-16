############################################
# SG OUTPUTS
############################################

output "lambda_security_group_id" {
  description = "ID of the security group attached to the Lambda function ENIs"
  value       = aws_security_group.lambda.id
}

output "endpoints_security_group_id" {
  description = "ID of the security group attached to the interface VPC endpoints"
  value       = aws_security_group.endpoints.id
}

output "rds_proxy_security_group_id" {
  description = "ID of the security group attached to the RDS Proxy"
  value       = aws_security_group.rds_proxy.id
}

output "database_security_group_id" {
  description = "ID of the security group attached to the RDS PostgreSQL database"
  value       = aws_security_group.database.id
}
