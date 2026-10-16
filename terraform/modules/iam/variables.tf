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

variable "db_master_user_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret holding the master credentials"
  type        = string
  sensitive   = true
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt RDS storage, secrets, and CloudWatch logs"
  type        = string
}

variable "rds_proxy_arn" {
  description = "ARN of the RDS Proxy"
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

variable "db_username" {
  type = string
}
