############################################
# VPC NETWORKING
############################################

locals {
  private_subnet_cidrs = { for i, az in var.availability_zones : az => cidrsubnet(var.vpc_cidr, var.subnet_newbits, i) }
  subnet_ids           = [for az in var.availability_zones : aws_subnet.private[az].id]
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # required for Interface Endpoint private DNS

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-vpc"
  })
}

# Private subnets ONLY: no IGW, no NAT, no 0.0.0.0/0 route anywhere.
resource "aws_subnet" "private" {
  for_each = local.private_subnet_cidrs

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-private-${each.key}", Tier = "private"
  })
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-private-rt-${each.key}"
  })
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Neutralise the default SG (no rules = nothing can use it by accident).
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
  tags = merge(var.common_tags, {
    Name = "${var.naming_prefix}-default-sg-unused"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.naming_prefix}-db-subnet-group"
  subnet_ids = local.subnet_ids
}

############################ Flow logs ############################
resource "aws_cloudwatch_log_group" "flow" {
  name              = "/vpc/${var.naming_prefix}/flow-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn
}

data "aws_iam_policy_document" "flow_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.current_account_id]
    }
  }
}

data "aws_iam_policy_document" "flow_perms" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
    resources = ["${aws_cloudwatch_log_group.flow.arn}:*"]
  }
}

resource "aws_iam_role" "flow" {
  name               = "${var.naming_prefix}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.flow_trust.json
}

resource "aws_iam_role_policy" "flow" {
  name   = "${var.naming_prefix}-write-flow-logs"
  role   = aws_iam_role.flow.id
  policy = data.aws_iam_policy_document.flow_perms.json
}

resource "aws_flow_log" "this" {
  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow.arn
  iam_role_arn             = aws_iam_role.flow.arn
  max_aggregation_interval = 60
}
