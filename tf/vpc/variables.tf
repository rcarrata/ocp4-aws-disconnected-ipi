variable "availability_zones" {
  type        = list(string)
  description = "The availability zones in which to provision subnets."
}

variable "cidr_block" {
  type = string
}

variable "clustername" {
  type = string
}

# variable "publish_strategy" {
#   type        = string
#   description = "The publishing strategy for endpoints like load balancers"
# }

variable "region" {
  type        = string
  description = "The target AWS region for the cluster."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to be applied to created resources."
}

variable "vpc" {
  type        = string
  description = "An existing network (VPC ID) into which the cluster should be installed."
}

variable "public_subnets" {
  type        = list(string)
  description = "Existing public subnets into which the cluster should be installed."
}

variable "private_subnets" {
  type        = list(string)
  description = "Existing private subnets into which the cluster should be installed."
}

# variable "airgapped" {
#   type = map(string)
#   default = {
#     airgapped  = false
#     repository = ""
#   }
# }
