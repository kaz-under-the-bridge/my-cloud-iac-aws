# Locals configuration for VPC
locals {
  enabled = false # VPCリソース作成のオン/オフフラグ

  vpc_config = {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    name                 = "vpc-UTBSandbox01"
  }

  subnets = {
    "public-a" = {
      cidr_block        = "10.0.0.0/24"
      availability_zone = "ap-northeast-1a"
      type              = "public"
      name              = "subnet-UTBSandbox01-public-a"
    }
    "public-c" = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "ap-northeast-1c"
      type              = "public"
      name              = "subnet-UTBSandbox01-public-c"
    }
    "protected-a" = {
      cidr_block        = "10.0.10.0/24"
      availability_zone = "ap-northeast-1a"
      type              = "protected"
      name              = "subnet-UTBSandbox01-protected-a"
    }
    "protected-c" = {
      cidr_block        = "10.0.11.0/24"
      availability_zone = "ap-northeast-1c"
      type              = "protected"
      name              = "subnet-UTBSandbox01-protected-c"
    }
    "private-a" = {
      cidr_block        = "10.0.20.0/24"
      availability_zone = "ap-northeast-1a"
      type              = "private"
      name              = "subnet-UTBSandbox01-private-a"
    }
    "private-c" = {
      cidr_block        = "10.0.21.0/24"
      availability_zone = "ap-northeast-1c"
      type              = "private"
      name              = "subnet-UTBSandbox01-private-c"
    }
  }

  nat_gateways = {
    "a" = {
      subnet_key = "public-a"
      name       = "ngw-UTBSandbox01-a"
      eip_name   = "eip-ngw-UTBSandbox01-a"
    }
    "c" = {
      subnet_key = "public-c"
      name       = "ngw-UTBSandbox01-c"
      eip_name   = "eip-ngw-UTBSandbox01-c"
    }
  }

  route_tables = {
    "public" = {
      name = "rtb-UTBSandbox01-public"
      routes = [
        {
          cidr_block   = "0.0.0.0/0"
          gateway_type = "internet_gateway"
        }
      ]
    }
    "private" = {
      name   = "rtb-UTBSandbox01-private"
      routes = []
    }
    "protected-a" = {
      name = "rtb-UTBSandbox01-protected-a"
      routes = [
        {
          cidr_block   = "0.0.0.0/0"
          gateway_type = "nat_gateway"
          nat_key      = "a"
        }
      ]
    }
    "protected-c" = {
      name = "rtb-UTBSandbox01-protected-c"
      routes = [
        {
          cidr_block   = "0.0.0.0/0"
          gateway_type = "nat_gateway"
          nat_key      = "c"
        }
      ]
    }
  }

  route_table_associations = {
    "public-a"    = { subnet_key = "public-a", route_table_key = "public" }
    "public-c"    = { subnet_key = "public-c", route_table_key = "public" }
    "protected-a" = { subnet_key = "protected-a", route_table_key = "protected-a" }
    "protected-c" = { subnet_key = "protected-c", route_table_key = "protected-c" }
    "private-a"   = { subnet_key = "private-a", route_table_key = "private" }
    "private-c"   = { subnet_key = "private-c", route_table_key = "private" }
  }
}

# VPC
resource "aws_vpc" "utb_sandbox_01" {
  count = local.enabled ? 1 : 0

  cidr_block           = local.vpc_config.cidr_block
  enable_dns_hostnames = local.vpc_config.enable_dns_hostnames
  enable_dns_support   = local.vpc_config.enable_dns_support

  tags = {
    Name = local.vpc_config.name
  }
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = local.enabled ? 1 : 0

  name              = "vpc-UTBSandbox01"
  retention_in_days = 7

  tags = {
    Name        = "vpc-UTBSandbox01"
    Application = "UTBSandbox01"
  }
}

# IAM Role for VPC Flow Logs
resource "aws_iam_role" "flow_logs_role" {
  count = local.enabled ? 1 : 0

  name = "fl-vpc-UTBSandbox01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for VPC Flow Logs
resource "aws_iam_policy" "flow_logs_policy" {
  count = local.enabled ? 1 : 0

  name = "FlowLogsPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "flow_logs_policy_attachment" {
  count = local.enabled ? 1 : 0

  role       = aws_iam_role.flow_logs_role[0].name
  policy_arn = aws_iam_policy.flow_logs_policy[0].arn
}

# VPC Flow Log
resource "aws_flow_log" "vpc_flow_log" {
  count = local.enabled ? 1 : 0

  iam_role_arn    = aws_iam_role.flow_logs_role[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.utb_sandbox_01[0].id

  tags = {
    Name = "vpc-UTBSandbox01"
  }
}

# Subnets
resource "aws_subnet" "main" {
  for_each = local.enabled ? local.subnets : {}

  vpc_id            = aws_vpc.utb_sandbox_01[0].id
  availability_zone = each.value.availability_zone
  cidr_block        = each.value.cidr_block

  tags = {
    Name = each.value.name
    Type = each.value.type
  }
}

# DB Subnet Group (only private subnets)
resource "aws_db_subnet_group" "main" {
  count = local.enabled ? 1 : 0

  name = "dbsubnet-utbsandbox01"
  subnet_ids = [
    for k, v in local.subnets : aws_subnet.main[k].id
    if v.type == "private"
  ]

  tags = {
    Name = "dbsubnet-UTBSandbox01"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = local.enabled ? 1 : 0

  vpc_id = aws_vpc.utb_sandbox_01[0].id

  tags = {
    Name = "igw-UTBSandbox01"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "ngw" {
  for_each = local.enabled ? local.nat_gateways : {}

  domain = "vpc"

  tags = {
    Name        = each.value.eip_name
    Application = "UTBSandbox01"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "ngw" {
  for_each = local.enabled ? local.nat_gateways : {}

  allocation_id = aws_eip.ngw[each.key].id
  subnet_id     = aws_subnet.main[each.value.subnet_key].id

  tags = {
    Name        = each.value.name
    Application = "UTBSandbox01"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "main" {
  for_each = local.enabled ? local.route_tables : {}

  vpc_id = aws_vpc.utb_sandbox_01[0].id

  dynamic "route" {
    for_each = each.value.routes
    content {
      cidr_block     = route.value.cidr_block
      gateway_id     = route.value.gateway_type == "internet_gateway" ? aws_internet_gateway.main[0].id : null
      nat_gateway_id = route.value.gateway_type == "nat_gateway" ? aws_nat_gateway.ngw[route.value.nat_key].id : null
    }
  }

  tags = {
    Name = each.value.name
  }
}

# Route Table Associations
resource "aws_route_table_association" "main" {
  for_each = local.enabled ? local.route_table_associations : {}

  subnet_id      = aws_subnet.main[each.value.subnet_key].id
  route_table_id = aws_route_table.main[each.value.route_table_key].id
}

# S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  count = local.enabled ? 1 : 0

  vpc_id       = aws_vpc.utb_sandbox_01[0].id
  service_name = "com.amazonaws.ap-northeast-1.s3"

  route_table_ids = [
    aws_route_table.main["protected-a"].id,
    aws_route_table.main["protected-c"].id
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "*"
      }
    ]
  })
}
