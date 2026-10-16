############################################
# SG VARIABLES
############################################

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}
