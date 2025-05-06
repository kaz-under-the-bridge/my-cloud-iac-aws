variable "aws_region_name" {}
variable "aws_vpc_id" {}
variable "aws_subnet_protected-a_id" {}
variable "aws_subnet_protected-c_id" {}
variable "ecs-vpce-sg-id" {}
variable "ec2-vpce-sg-id" {}

variable "vpc_endpoint_ecs" {
  type    = list(any)
  default = ["ecr.api", "ecr.dkr", "secretsmanager"]
}

variable "vpc_endpoint_common" {
  type    = list(any)
  default = ["logs", "ssm", "ssmmessages"]
}

variable "system_name" {}
variable "environment" {}
