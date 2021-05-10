# Define how can be the VPC Cidr for the control-plane and compute nodes
locals {
  new_private_cidr_range = cidrsubnet(data.aws_vpc.cluster_vpc.cidr_block, 6, 0)
  new_public_cidr_range  = cidrsubnet(data.aws_vpc.cluster_vpc.cidr_block, 1, 0)
}

# VPC for OCP4 cluster
resource "aws_vpc" "new_vpc" {

  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    {
      "Name" = "${var.clustername}-vpc"
    },
    var.tags,
  )

}

# Define the VPC DHCP Options 
# VPC generates OK the DHCP
# resource "aws_vpc_dhcp_options" "main" {
#   domain_name         = format("%s.compute.internal", var.region)
#   domain_name_servers = ["AmazonProvidedDNS"]

#   tags = var.tags
# }

# resource "aws_vpc_dhcp_options_association" "main" {

#   vpc_id          = data.aws_vpc.cluster_vpc.id
#   dhcp_options_id = aws_vpc_dhcp_options.main.id
# }
