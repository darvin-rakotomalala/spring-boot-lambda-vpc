############################################
# SNS VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for encryption"
  type        = string
}

variable "alarm_email" {
  description = "Optional e-mail subscribed to the alarm topic (must confirm the subscription)."
  type        = string
}
