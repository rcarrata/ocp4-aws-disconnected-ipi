
## private elb endpoint
data "aws_vpc_endpoint_service" "elb" {
  service = "elasticloadbalancing"
}

resource "aws_vpc_endpoint" "private_elb" {

  vpc_id            = data.aws_vpc.cluster_vpc.id
  service_name      = data.aws_vpc_endpoint_service.elb.service_name
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.private_endpoint.id
  ]

  subnet_ids = aws_subnet.private_subnet.*.id

  tags = merge(
    {
      "Name" = "${var.clustername}-elb-vpce"
    },
    var.tags,
  )

}

## private ec2 endpoint
data "aws_vpc_endpoint_service" "ec2" {
  service = "ec2"
}

resource "aws_vpc_endpoint" "private_ec2" {
  vpc_id            = data.aws_vpc.cluster_vpc.id
  service_name      = data.aws_vpc_endpoint_service.ec2.service_name
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.private_endpoint.id
  ]

  subnet_ids = aws_subnet.private_subnet.*.id

  tags = merge(
    {
      "Name" = "${var.clustername}-ec2-vpce"
    },
    var.tags,
  )

}

resource "aws_vpc_endpoint" "private_s3" {
  vpc_id            = data.aws_vpc.cluster_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  private_dns_enabled = false

  tags = merge(
    {
      "Name" = "${var.clustername}-s3-vpce"
    },
    var.tags,
  )

}

resource "aws_vpc_endpoint_route_table_association" "private_route_table_association" {
  route_table_id  = aws_route_table.private_routes.id
  vpc_endpoint_id = aws_vpc_endpoint.private_s3.id
}

