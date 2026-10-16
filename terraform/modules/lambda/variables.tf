############################################
# LAMBDA VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "lambda_handler" {
  type = string
}

variable "lambda_memory_mb" {
  description = "Memory allocated to the Lambda function, in MB (CPU power scales proportionally with memory)"
  type        = number
}

variable "lambda_timeout_s" {
  description = "Keep <= 29s: API Gateway REST integration timeout."
  type        = number
}

variable "lambda_architecture" {
  description = "Instruction set architecture of the Lambda function: arm64 or x86_64"
  type        = string
}

variable "lambda_reserved_concurrency" {
  description = "-1 = unreserved. Set a cap to protect the DB from a Lambda stampede."
  type        = number
}

variable "latency_strategy" {
  description = <<-EOT
    SnapStart and Provisioned Concurrency are mutually exclusive on AWS.
      snapstart                - cheaper, ~10x faster cold starts (default)
      provisioned_concurrency  - zero cold starts, autoscaled, pay for idle capacity
  EOT
  type        = string

  validation {
    condition     = contains(["snapstart", "provisioned_concurrency"], var.latency_strategy)
    error_message = "latency_strategy must be snapstart or provisioned_concurrency."
  }
}

variable "pc_min_capacity" {
  description = "Minimum number of provisioned concurrency units the Lambda function is scaled down to"
  type        = number
}

variable "pc_max_capacity" {
  description = "Maximum number of provisioned concurrency units the Lambda function can be scaled up to"
  type        = number
}

variable "pc_target_utilization" {
  description = "Target tracking value (0-1) for LambdaProvisionedConcurrencyUtilization."
  type        = number
}

variable "log_retention_days" {
  description = "Number of days CloudWatch retains log events in the log groups before expiring them"
  type        = number
}

variable "log_group_lambda_name" {
  description = "Name of the CloudWatch log group used by the Lambda function"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt RDS storage, secrets, and CloudWatch logs"
  type        = string
}

variable "lambda_iam_role_arn" {
  description = "ARN of the IAM role assumed by the Lambda function"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of IDs of the private subnets"
  type        = list(string)
}

variable "lambda_security_group_id" {
  description = "ID of the security group attached to the Lambda function ENIs"
  type        = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "environment" {
  description = "Environment name"
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

variable "rds_db_port" {
  description = "Port on which the RDS database instance accepts connections"
  type        = string
}

variable "rds_proxy_endpoint" {
  description = "Connection endpoint (hostname) of the RDS Proxy, to be used by the application instead of the database endpoint"
  type        = string
}

variable "random_password_db_master_result" {
  description = "Random password db master result"
  type        = string
}

variable "lambda_vpc_access_policy_arn" {
  description = "ARN of the managed policy (AWSLambdaVPCAccessExecutionRole) attached to the Lambda role for VPC and ENI access"
  type        = string
}

variable "lambda_inline_policy_name" {
  description = "Name of the inline IAM policy attached to the Lambda role"
  type        = string
}

variable "db_proxy_target_arn" {
  description = "ARN of the RDS DB instance registered as a target of the DB proxy"
  type        = string
}

variable "interface_endpoint" {
  description = "Map of interface VPC endpoint service to its endpoint ID"
  type        = string
}

variable "lambda_environment" {
  description = "Extra environment variables for the function (merged over the defaults in lambda.tf)."
  type        = map(string)
}
