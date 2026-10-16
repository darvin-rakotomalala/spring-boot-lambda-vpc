############################################
# VPC VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "vpc_cidr" {
  description = "Use RFC1918 space. (18.25.15.0/25 from the spec is public Amazon/third-party space and can cause routing conflicts.)"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "availability_zones" {
  type = list(string)
}

variable "subnet_newbits" {
  description = "Bits added to the VPC prefix for each subnet. /25 + 2 = /27 (matches the spec layout)."
  type        = number
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

variable "log_retention_days" {
  description = "Number of days to retain logs before they expire"
  type        = number
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  type        = string
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}
