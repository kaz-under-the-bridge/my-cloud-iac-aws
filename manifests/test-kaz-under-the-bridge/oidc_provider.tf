locals {
  oidc_providers = [
    {
      name : "terraform_cloud",
      url : "https://app.terraform.io"
      client_id_list : ["aws.workload.identity"],
      thumbprint_list : ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"],
    }
  ]
}


resource "aws_iam_openid_connect_provider" "main" {
  for_each = { for provider in local.oidc_providers : provider.name => provider }

  url = each.value.url

  client_id_list = each.value.client_id_list

  thumbprint_list = each.value.thumbprint_list
}
