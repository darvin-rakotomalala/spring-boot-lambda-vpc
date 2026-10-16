############################################
# KMS VARIABLES
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

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
}

variable "lambda_iam_role_arn" {
  description = "ARN of the IAM role assumed by the Lambda function"
  type        = string
}
