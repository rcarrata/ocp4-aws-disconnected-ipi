variable "ec2_ami" {
  type    = string
  default = ""
}

variable "instance_type" {
  type = string
}

variable "clustername" {
  description = "The domain for the cluster that all DNS records must belong"
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to be applied to created resources."
}

variable "root_volume_size" {
  type        = string
  description = "The size of the volume in gigabytes for the root block device."
}

variable "availability_zones" {
  type        = list(string)
  description = "List of the availability zones in which to create the masters. The length of this list must match instance_count."
}

variable "az_to_subnet_id" {
  type        = map(string)
  description = "Map from availability zone name to the ID of the subnet in that availability zone"
}

variable "bastion_sg_id" {
  description = "Bastion security group for the bastion"
  type        = list(string)
}

variable "ssh_key" {
  description = "The domain for the cluster that all DNS records must belong"
  type        = string
}
