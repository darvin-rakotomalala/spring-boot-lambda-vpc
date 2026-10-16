############################################
# CLOUDWATCH OUTPUTS
############################################

output "lambda_errors_metric_filter_name" {
  description = "Name of the CloudWatch log metric filter that counts ERROR-level application log entries"
  value       = aws_cloudwatch_log_metric_filter.lambda_errors.name
}

output "app_errors_alarm_arn" {
  description = "ARN of the alarm that fires on ERROR-level application log entries"
  value       = aws_cloudwatch_metric_alarm.app_errors.arn
}

output "api_5xx_alarm_arn" {
  description = "ARN of the alarm that fires on API Gateway 5XX errors"
  value       = aws_cloudwatch_metric_alarm.api_5xx.arn
}

output "api_4xx_alarm_arn" {
  description = "ARN of the alarm that fires on API Gateway 4XX errors"
  value       = aws_cloudwatch_metric_alarm.api_4xx.arn
}

output "low_success_rate_alarm_arn" {
  description = "ARN of the alarm that fires when the API success rate drops below the minimum threshold"
  value       = aws_cloudwatch_metric_alarm.low_success_rate.arn
}

output "lambda_errors_alarm_arn" {
  description = "ARN of the alarm that fires on a high Lambda error count"
  value       = aws_cloudwatch_metric_alarm.lambda_errors.arn
}

output "lambda_throttles_alarm_arn" {
  description = "ARN of the alarm that fires when the Lambda function is throttled"
  value       = aws_cloudwatch_metric_alarm.lambda_throttles.arn
}

output "critical_composite_alarm_arn" {
  description = "ARN of the composite alarm that combines the critical Lambda error, throttle and success-rate alarms"
  value       = aws_cloudwatch_composite_alarm.critical.arn
}
