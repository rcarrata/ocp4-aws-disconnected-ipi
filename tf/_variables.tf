## Variables for AWS Resources

variable "aws_access_key_id" {
  type        = string
  description = "AWS Access Key"
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS Secret"
}

variable "aws_ami" {
  type        = string
  description = <<EOF
AMI for the bastion host. Recommended RHEL8 / Centos8
EOF
}

# variable "aws_ami" {
#   type        = string
#   description = <<EOF
# AMI for all nodes.  An encrypted copy of this AMI will be used.
# The list of RedHat CoreOS AMI for each of the AWS region can be found in:
# `https://github.com/openshift/installer/blob/master/data/data/rhcos-amd64.json`
# Get the History of the file to find an older AMI list
# EOF
# }

variable "aws_extra_tags" {
  type = map(string)

  description = <<EOF
(optional) Extra AWS tags to be applied to created resources.

Example: `{ "owner" = "me", "kubernetes.io/cluster/mycluster" = "owned" }`
EOF

  default = {}
}

variable "aws_ssh_key" {
  type        = string
  description = "The ssh key pair for AWS instances"
}


variable "aws_bastion_instance_type" {
  type        = string
  description = "The ec2 AWS instance type for the bastion."
}

variable "aws_bastion_root_volume_size" {
  type        = string
  description = "The root volume size of AWS instance type for the bastion."
  default     = "200"
}

variable "aws_region" {
  type        = string
  description = "The target AWS region for the cluster."
}

variable "aws_azs" {
  type        = list(string)
  description = "The availability zones in which to create the nodes."
}

variable "aws_vpc" {
  type        = string
  default     = null
  description = "(optional) An existing network (VPC ID) into which the cluster should be installed."
}

variable "aws_public_subnets" {
  type        = list(string)
  default     = null
  description = "(optional) Existing public subnets into which the cluster should be installed."
}

variable "aws_private_subnets" {
  type        = list(string)
  default     = null
  description = "(optional) Existing private subnets into which the cluster should be installed."
}

# variable "aws_publish_strategy" {
#   type        = string
#   description = "The cluster publishing strategy, either Internal or External"
#   default     = "External"
# }

## Variables for OCP4 Installation

variable "cidr_block" {
  type = string

  description = <<EOF
The IP address space from which to assign machine IPs.
Default "10.0.0.0/16"
EOF
  default     = "10.0.0.0/16"
}

variable "base_domain" {
  type        = string
  description = "The base DNS domain of the cluster."
}

variable "clustername" {
  type = string

  description = <<EOF
The name of the cluster. It must NOT contain a trailing period. Some
DNS providers will automatically add this if necessary.

Note: This field MUST be set manually prior to creating the cluster.
EOF

}

variable "use_ipv4" {
  type        = bool
  default     = true
  description = <<EOF
Should the cluster be created with ipv4 networking. (default = true)
EOF

}

# variable "machine_cidr" {
#   type = string

#   description = <<EOF
# The IP address space from which to assign machine IPs.
# Default "10.0.0.0/16"
# EOF
#   default     = "10.0.0.0/16"
# }
