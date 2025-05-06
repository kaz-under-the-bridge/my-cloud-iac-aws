resource "aws_route53_zone" "kaz_under_the_bridge" {
  name = "aws.under-the-bridge.work"

  tags = {
    Name = "aws.under-the-bridge.work"
  }
}
