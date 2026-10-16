############################################
# CLOUDWATCH VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

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

variable "alarm_topic_arn" {
  description = "ARN of the SNS topic that receives alarm notifications"
  type        = string
}

variable "log_group_lambda_name" {
  description = "Name of the CloudWatch log group used by the Lambda function"
  type        = string
}

variable "api_gateway_rest_api_name" {
  description = "Name of the API Gateway REST API fronting the Spring Boot Lambda"
  type        = string
}

variable "api_gateway_stage_name" {
  description = "Name of the API Gateway stage the REST API is deployed to"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
}
