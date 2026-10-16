############################################
# Account/partition/region lookups
############################################

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

# Availability zones available in the target region
data "aws_availability_zones" "available" {
  state = "available"
}
