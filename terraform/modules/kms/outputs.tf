############################################
# KMS OUTPUTS
############################################

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt RDS storage, secrets, and CloudWatch logs"
  value       = aws_kms_key.main.arn
}
