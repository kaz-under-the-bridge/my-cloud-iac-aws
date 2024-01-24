locals {
  bukects = [
    {
      name : "twilio-voice-data",
      policy_file : "./policies/twilio_voice.json",
    }
  ]
}

resource "aws_s3_bucket" "main" {
  for_each = { for bucket in local.bukects : bucket.name => bucket }

  bucket = each.value.name
}

resource "aws_s3_bucket_policy" "main" {
  for_each = { for bucket in local.bukects : bucket.name => bucket }

  bucket = aws_s3_bucket.main[each.value.name].id
  #policy = jsonencode(file(each.value.policy_file))
  policy = file(each.value.policy_file)
}
