# cloudformationでVPC定義を試したときのサンプルコード(テンプレートは削除済)
#locals {
#  cfn_templates = [
#    {
#      name     = "vpc-network-configuration"
#      template = file("${path.module}/vpc_cloudformation.tpl")
#    }
#  ]
#}
#
#resource "aws_cloudformation_stack" "main" {
#  for_each = { for tpl in local.cfn_templates : tpl.name => tpl }
#
#  name          = each.value.name
#  template_body = each.value.template
#
#  capabilities = ["CAPABILITY_NAMED_IAM"]
#}
#
