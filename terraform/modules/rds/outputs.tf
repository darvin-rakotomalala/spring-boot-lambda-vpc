############################################
# RDS OUTPUTS
############################################

output "rds_identifier" {
  description = "Identifier of the RDS PostgreSQL instance"
  value       = aws_db_instance.this.identifier
}

output "rds_arn" {
  description = "ARN of the RDS PostgreSQL instance"
  value       = aws_db_instance.this.arn
}

output "rds_endpoint" {
  description = "Connection endpoint (host:port) of the RDS PostgreSQL primary instance"
  value       = aws_db_instance.this.endpoint
}

output "rds_address" {
  description = "Hostname only of the RDS PostgreSQL primary instance, for use in application configuration"
  value       = aws_db_instance.this.address
}

output "rds_port" {
  description = "Port the RDS PostgreSQL instance listens on"
  value       = aws_db_instance.this.port
}

output "rds_engine_version" {
  description = "PostgreSQL engine version deployed"
  value       = aws_db_instance.this.engine_version_actual
}

output "rds_proxy_name" {
  description = "Name of the RDS Proxy"
  value       = aws_db_proxy.this.name
}

output "rds_proxy_arn" {
  description = "ARN of the RDS Proxy"
  value       = aws_db_proxy.this.arn
}

output "rds_proxy_endpoint" {
  description = "Connection endpoint (hostname) of the RDS Proxy, to be used by the application instead of the database endpoint"
  value       = aws_db_proxy.this.endpoint
}

output "rds_db_port" {
  description = "Port on which the RDS database instance accepts connections"
  value       = local.db_port
}

output "db_proxy_target_arn" {
  description = "ARN of the RDS DB instance registered as a target of the DB proxy"
  value       = aws_db_proxy_target.this.target_arn
}
