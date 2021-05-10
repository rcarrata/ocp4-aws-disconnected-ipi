# allow anybody in the VPC to talk to ELB, EC2 and S3 through the private endpoint
resource "aws_security_group" "private_endpoint" {
  name   = "${var.clustername}-EP-elb"
  vpc_id = data.aws_vpc.cluster_vpc.id

  tags = merge(
    {
      "Name" = "${var.clustername}-EP-sg"
    },
    var.tags,
  )
}

resource "aws_security_group_rule" "private_endpoint_ingress" {
  type = "ingress"

  from_port = 0
  to_port   = 65535
  protocol  = "tcp"
  cidr_blocks = [
    var.cidr_block
  ]

  security_group_id = aws_security_group.private_endpoint.id
}

resource "aws_security_group_rule" "private_endpoint_egress" {
  type = "egress"

  from_port = 0
  to_port   = 0
  protocol  = "all"
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  security_group_id = aws_security_group.private_endpoint.id
}
