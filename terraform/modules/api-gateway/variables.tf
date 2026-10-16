############################################
# API GATEWAY VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "api_authorization" {
  description = "NONE, AWS_IAM or CUSTOM/COGNITO_USER_POOLS (needs extra wiring). Prefer AWS_IAM or an authorizer for non-public APIs."
  type        = string
}

variable "api_throttle_rate" {
  description = "Steady-state API Gateway request rate limit, in requests per second"
  type        = number
}

variable "api_throttle_burst" {
  description = "Maximum number of concurrent requests API Gateway allows in a burst before throttling"
  type        = number
}

variable "create_apigw_account_role" {
  description = "API Gateway needs ONE account-wide CloudWatch role for access logs. Set false if already configured."
  type        = bool
}

variable "log_retention_days" {
  description = "Number of days to retain logs before they expire"
  type        = number
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  type        = string
}

variable "current_partition" {
  description = "Current partition account ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_alias" {
  description = "Name of the Lambda function alias (e.g. live)"
  type        = string
}

variable "lambda_alias_live_invoke_arn" {
  description = "Invoke ARN of the live Lambda alias, used to integrate it with API Gateway"
  type        = string
}
