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
  publish_strategy   = var.aws_publish_strategy
  #airgapped         = var.airgapped

  tags = local.tags
}
