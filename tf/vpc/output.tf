output "vpc_id" {
  value = data.aws_vpc.cluster_vpc.id
}

output "vpc_cidrs" {
  value = [data.aws_vpc.cluster_vpc.cidr_block]
}

output "az_to_private_subnet_id" {
  value = zipmap(data.aws_subnet.private.*.availability_zone, data.aws_subnet.private.*.id)
}

output "az_to_public_subnet_id" {
  value = zipmap(data.aws_subnet.public.*.availability_zone, data.aws_subnet.public.*.id)
}

output "public_subnet_ids" {
  value = data.aws_subnet.public.*.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}
