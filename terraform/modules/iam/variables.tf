############################################
# IAM VARIABLES
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

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
}

variable "db_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS master credentials"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt RDS storage, secrets, and CloudWatch logs"
  type        = string
}

variable "rds_proxy_arn" {
  description = "ARN of the RDS Proxy"
  type        = string
}

variable "db_username" {
  type = string
}
