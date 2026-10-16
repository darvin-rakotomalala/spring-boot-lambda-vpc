############################################
# VPC OUTPUTS
############################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  value       = local.subnet_ids
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group spanning the private subnets, used when creating the RDS instance"
  value       = aws_db_subnet_group.this.name
}

output "private_route_table_ids" {
  description = "Map of availability zone to the ID of its private route table"
  value       = { for az, rt in aws_route_table.private : az => rt.id }
}
