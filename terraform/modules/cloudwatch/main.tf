############################################
# MONITORING
############################################

############################ Log metric filter ############################
resource "aws_cloudwatch_log_metric_filter" "lambda_errors" {
  name           = "${var.naming_prefix}-app-errors"
  log_group_name = var.log_group_lambda_name
  pattern        = "{ $.level = \"ERROR\" }"

  metric_transformation {
    name          = "ApplicationErrors"
    namespace     = "${var.naming_prefix}/Lambda"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name          = "${var.naming_prefix}-app-errors-logged"
  namespace           = "${var.naming_prefix}/Lambda"
  metric_name         = "ApplicationErrors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_topic_arn]
  # ok_actions          = [var.alarm_topic_arn]
}

############################ API Gateway alarms ############################
locals {
  api_dims = { ApiName = var.api_gateway_rest_api_name, Stage = var.api_gateway_stage_name }
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${var.naming_prefix}-api-5xx"
  namespace           = "AWS/ApiGateway"
  metric_name         = "5XXError"
  dimensions          = local.api_dims
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = var.api_5xx_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_topic_arn]
  # ok_actions          = [var.alarm_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "api_4xx" {
  alarm_name          = "${var.naming_prefix}-api-4xx"
  namespace           = "AWS/ApiGateway"
  metric_name         = "4XXError"
  dimensions          = local.api_dims
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = var.api_4xx_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_topic_arn]
}

# Success rate = 100 * (1 - 5XX / requests); no traffic counts as healthy.
resource "aws_cloudwatch_metric_alarm" "low_success_rate" {
  alarm_name          = "${var.naming_prefix}-low-success-rate"
  comparison_operator = "LessThanThreshold"
  threshold           = var.min_success_rate_percent
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_topic_arn]
  # ok_actions          = [var.alarm_topic_arn]

  metric_query {
    id          = "rate"
    expression  = "IF(requests > 0, 100 * (1 - errors / requests), 100)"
    label       = "API success rate (%)"
    return_data = true
  }
  metric_query {
    id = "requests"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "Count"
      dimensions  = local.api_dims
      period      = 60
      stat        = "Sum"
    }
  }
  metric_query {
    id = "errors"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "5XXError"
      dimensions  = local.api_dims
      period      = 60
      stat        = "Sum"
    }
  }
}

############################ Lambda alarms ############################
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.naming_prefix}-high-error-rate"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = var.lambda_function_name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_topic_arn]
  # ok_actions          = [var.alarm_topic_arn]
}

# Any throttle is early warning: raise limits before users notice.
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.naming_prefix}-high-throttles"
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  dimensions          = { FunctionName = var.lambda_function_name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_topic_arn]
  # ok_actions          = [var.alarm_topic_arn]
}

resource "aws_cloudwatch_composite_alarm" "critical" {
  alarm_name = "${var.naming_prefix}-critical-lambda-issues"
  alarm_rule = join(" OR ", [
    "ALARM(\"${aws_cloudwatch_metric_alarm.lambda_errors.alarm_name}\")",
    "ALARM(\"${aws_cloudwatch_metric_alarm.lambda_throttles.alarm_name}\")",
    "ALARM(\"${aws_cloudwatch_metric_alarm.low_success_rate.alarm_name}\")",
  ])
  alarm_actions = [var.alarm_topic_arn]
  # ok_actions    = [var.alarm_topic_arn]
}
