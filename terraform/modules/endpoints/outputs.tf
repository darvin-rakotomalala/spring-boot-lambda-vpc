############################################
# VPC ENDPOINTS OUTPUTS
############################################

output "gateway_endpoint_ids" {
  description = "Map of gateway VPC endpoint service (s3, dynamodb) to its endpoint ID"
  value       = { for k, v in aws_vpc_endpoint.gateway : k => v.id }
}

output "interface_endpoint_ids" {
  description = "Map of interface VPC endpoint service to its endpoint ID"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "interface_endpoint_dns_entries" {
  description = "Map of interface VPC endpoint service to its DNS entries (DNS name and hosted zone ID)"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.dns_entry }
}

output "interface_endpoint" {
  description = "Map of interface VPC endpoint service to its endpoint ID"
  value       = { for svc, ep in aws_vpc_endpoint.interface : svc => ep.id }
}
