############################################
# MAIN VARIABLES
############################################

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "compliance" {
  description = "Compliance"
  type        = string
}

variable "bucket_name" {
  description = "Bucket name"
  type        = string
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "lambda_environment" {
  description = "Extra environment variables for the function (merged over the defaults in lambda.tf)."
  type        = map(string)
}

variable "vpc_cidr" {
  description = "Use RFC1918 space. (18.25.15.0/25 from the spec is public Amazon/third-party space and can cause routing conflicts.)"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "availability_zones" {
  description = "List of availability zones in which subnets and other zonal resources are created."
  type        = list(string)
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

variable "alarm_email" {
  description = "Optional e-mail subscribed to the alarm topic (must confirm the subscription)."
  type        = string
}

variable "db_name" {
  description = "Name of the initial database created in the RDS instance."
  type        = string
}

variable "db_username" {
  description = "Master (admin) username for the RDS database."
  type        = string
}

variable "db_engine_version" {
  description = "Major version; RDS picks the latest minor and auto-upgrades minors."
  type        = string
}

variable "db_parameter_group_family" {
  description = "Parameter group family for the RDS instance (must match the engine major version, e.g. postgres16)."
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class (compute and memory size) for the database."
  type        = string
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for the RDS instance, in GiB."
  type        = number
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
  description = "Number of days to retain automated RDS backups."
  type        = number
}

variable "proxy_max_connections_percent" {
  description = "Maximum percentage of the database's max_connections that the RDS Proxy may use."
  type        = number
}

variable "lambda_handler" {
  description = "Fully qualified handler (class::method) that Lambda invokes as the function entry point."
  type        = string
}

variable "lambda_memory_mb" {
  description = "Memory allocated to the Lambda function, in MB (CPU scales proportionally)."
  type        = number
}

variable "lambda_timeout_s" {
  description = "Keep <= 29s: API Gateway REST integration timeout."
  type        = number
}

variable "lambda_architecture" {
  description = "Instruction set architecture for the Lambda function (arm64 or x86_64)."
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
  description = "Minimum provisioned concurrency capacity for autoscaling (used when latency_strategy is provisioned_concurrency)."
  type        = number
}

variable "pc_max_capacity" {
  description = "Maximum provisioned concurrency capacity for autoscaling (used when latency_strategy is provisioned_concurrency)."
  type        = number
}

variable "pc_target_utilization" {
  description = "Target tracking value (0-1) for LambdaProvisionedConcurrencyUtilization."
  type        = number
}

variable "api_5xx_threshold" {
  description = "Number of API Gateway 5XX errors within a period at or above which the 5XX alarm fires"
  type        = number
}

variable "api_4xx_threshold" {
  description = "Number of API Gateway 4XX errors within a period at or above which the 4XX alarm fires"
  type        = number
}

variable "min_success_rate_percent" {
  description = "Minimum acceptable API success rate (percent of non-5XX responses); the alarm fires when the rate drops below this value"
  type        = number
}

variable "api_authorization" {
  description = "NONE, AWS_IAM or CUSTOM/COGNITO_USER_POOLS (needs extra wiring). Prefer AWS_IAM or an authorizer for non-public APIs."
  type        = string
}

variable "api_throttle_rate" {
  description = "Steady-state API Gateway throttle limit, in requests per second."
  type        = number
}

variable "api_throttle_burst" {
  description = "API Gateway burst throttle limit, i.e. the maximum number of concurrent requests allowed in a burst."
  type        = number
}

variable "create_apigw_account_role" {
  description = "API Gateway needs ONE account-wide CloudWatch role for access logs. Set false if already configured."
  type        = bool
}
