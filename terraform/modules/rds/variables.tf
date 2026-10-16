############################################
# RDS VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_engine_version" {
  description = "Major version; RDS picks the latest minor and auto-upgrades minors."
  type        = string
}

variable "db_parameter_group_family" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}

variable "db_max_allocated_storage" {
  description = "Storage autoscaling ceiling (GiB). Set equal to allocated to disable."
  type        = number
}

variable "db_multi_az" {
  description = "Standby in another AZ. If false the instance is pinned to the first AZ (spec behaviour)."
  type        = bool
}

variable "db_backup_retention_days" {
  type = number
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "rds_enhanced_monitoring_role_arn" {
  description = "ARN of the IAM role used for RDS Enhanced Monitoring"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  type        = list(string)
}

variable "rds_proxy_security_group_id" {
  description = "ID of the security group attached to the RDS Proxy"
  type        = string
}

variable "rds_proxy_role_arn" {
  description = "ARN of the IAM role assumed by the RDS Proxy to read the database secret"
  type        = string
}

variable "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS master credentials"
  type        = string
}

variable "rds_proxy_policy_name" {
  description = "Name of the inline IAM policy granting the RDS Proxy role access to the database secret"
  type        = string
}

variable "interface_endpoint" {
  description = "Map of interface VPC endpoint service to its endpoint ID"
  type        = string
}

variable "proxy_iam_auth" {
  description = "REQUIRED forces clients to use IAM tokens (no password in the app). DISABLED = password from Secrets Manager."
  type        = string

  validation {
    condition     = contains(["DISABLED", "REQUIRED"], var.proxy_iam_auth)
    error_message = "proxy_iam_auth must be DISABLED or REQUIRED."
  }
}

variable "proxy_max_connections_percent" {
  description = "Maximum percentage of the database's max_connections that the RDS Proxy is allowed to use (1-100)"
  type        = number
}

variable "log_retention_days" {
  description = "Number of days to retain logs before they expire"
  type        = number
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  type        = string
}

variable "availability_zones" {
  type = list(string)
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group spanning the private subnets, used when creating the RDS instance"
  type        = string
}

variable "database_security_group_id" {
  description = "ID of the security group attached to the RDS PostgreSQL database"
  type        = string
}
