locals {
  iam_roles = [
    {
      name : "tfc_oidc_role",
      policy_file : "./policies/tfc_oidc_role.json",
      tags = {}
    }
  ]
}

resource "aws_iam_role" "main" {
  for_each = { for role in local.iam_roles : role.name => role }

  name               = each.value.name
  assume_role_policy = file(each.value.policy_file)
}
