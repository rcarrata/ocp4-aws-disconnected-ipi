resource "aws_route53_zone" "internal" {
  name          = var.base_domain
  force_destroy = true

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(
    {
      "Name" = "${var.clustername}"
    },
    var.tags,
  )

}

resource "aws_route53_record" "bastion" {

  zone_id = aws_route53_zone.internal.zone_id
  name    = "bastion.${var.base_domain}"
  type    = "A"
  ttl     = "300"
  records = [var.bastion_instance_ip[0]]

}