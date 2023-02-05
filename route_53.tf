resource "aws_route53_zone" "alt-project" {
  name = "iamonuwacj.me"
}


resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.alt-project.zone_id
  name    = "iamonuwacj.me"
  type    = "A"

  alias {
    name                   = aws_elb.alt-terra-elb.dns_name
    zone_id                = aws_elb.alt-terra-elb.zone_id
    evaluate_target_health = true
  }
}
