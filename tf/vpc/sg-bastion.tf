resource "aws_security_group" "bastion" {
  vpc_id = data.aws_vpc.cluster_vpc.id

  timeouts {
    create = "20m"
  }

  tags = merge(
    {
      "Name" = "${var.clustername}-bastion-sg"
    },
    var.tags,
  )
}


resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  security_group_id = aws_security_group.bastion.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "bastion_ingress_icmp" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion.id

  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = -1
  to_port     = -1
}

resource "aws_security_group_rule" "bastion_ingress_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion.id

  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 22
  to_port     = 22
}

resource "aws_security_group_rule" "proxy" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion.id

  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 3128
  to_port     = 3128
}

resource "aws_security_group_rule" "registry" {
  type              = "ingress"
  security_group_id = aws_security_group.bastion.id

  protocol    = "tcp"
  cidr_blocks = [data.aws_vpc.cluster_vpc.cidr_block]
  from_port   = 5000
  to_port     = 5000
}
