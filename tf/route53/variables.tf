variable "clustername" {
  description = "The domain for the cluster that all DNS records must belong"
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to be applied to created resources."
}


variable "bastion_instance_ip" {
  description = "The bastion Private IP of the Bastion host"
  type        = list(string)
}

variable "base_domain" {
  description = "The base domain for the installation"
  type        = string
}

variable "vpc_id" {
  description = "The VPC used to create the private route53 zone."
}

