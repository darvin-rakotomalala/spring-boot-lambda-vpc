############################################
# SNS OUTPUTS
############################################

output "alarm_topic_arn" {
  description = "ARN of the SNS topic that receives alarm notifications"
  value       = aws_sns_topic.alarms.arn
}
