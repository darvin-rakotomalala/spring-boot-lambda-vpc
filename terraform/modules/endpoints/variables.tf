############################################
# VPC ENDPOINTS VARIABLES
############################################

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_route_table_ids" {
  description = "Map of availability zone to the ID of its private route table"
  type        = list(string)
}

variable "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS master credentials"
  type        = string
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "interface_endpoint_services" {
  description = <<-EOT
    Interface endpoints to create (short service names). Each one costs ~$0.01/h per AZ,
    so only keep what the workload really calls. Secrets Manager + Logs are required here.
    Add "sns", "sqs", "events" only if the app uses them.
  EOT
  type        = list(string)

  validation {
    condition     = contains(var.interface_endpoint_services, "secretsmanager") && contains(var.interface_endpoint_services, "logs")
    error_message = "secretsmanager and logs endpoints are mandatory (no internet route)."
  }
}

variable "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  type        = list(string)
}

variable "endpoints_security_group_id" {
  description = "ID of the security group attached to the interface VPC endpoints"
  type        = string
}
