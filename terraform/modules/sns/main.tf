############################################
# SNS
############################################

resource "aws_sns_topic" "alarms" {
  name              = "${var.naming_prefix}-alarms"
  kms_master_key_id = var.kms_key_arn

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-alarms"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
