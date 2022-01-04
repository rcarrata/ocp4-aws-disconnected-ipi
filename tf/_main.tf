terraform {
  backend "local" {}

  required_version = ">= 0.14"
}

locals {
  tags = merge(
    {
      "owned" = "${var.clustername}"
    },
    var.aws_extra_tags,
  )
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}

module "vpc" {
  source             = "./vpc"
  cidr_block         = var.cidr_block
  clustername        = var.clustername
  region             = var.aws_region
  vpc                = var.aws_vpc
  private_subnets    = var.aws_private_subnets
  availability_zones = var.aws_azs
  public_subnets     = var.aws_public_subnets
  # publish_strategy   = var.aws_publish_strategy
  #airgapped         = var.airgapped

  tags = local.tags
}

module "bastion" {
  source = "./bastion"

  clustername   = var.clustername
  instance_type = var.aws_bastion_instance_type

  tags = local.tags

  availability_zones = var.aws_azs
  az_to_subnet_id    = module.vpc.az_to_public_subnet_id
  bastion_sg_id      = [module.vpc.bastion_sg_id]
  root_volume_size   = var.aws_bastion_root_volume_size
  ec2_ami            = var.aws_ami
  ssh_key            = var.aws_ssh_key
}

module "route53" {
  source = "./route53"

  clustername         = var.clustername
  base_domain         = var.base_domain
  bastion_instance_ip = module.bastion.private_ip_address
  vpc_id              = module.vpc.vpc_id

  tags = local.tags
}
