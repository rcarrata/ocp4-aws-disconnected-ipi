variable "clustername" {
  description = "The domain for the cluster that all DNS records must belong"
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags to be applied to created resources."
}

variable "publish_strategy" {
  type        = string
  description = <<EOF
The publishing strategy for endpoints like load balancers

Because of the issue https://github.com/hashicorp/terraform/issues/12570, the consumers cannot count 0/1
based on if api_external_lb_dns_name for example, which will be null when there is no external lb for API.
So publish_strategy serves an coordinated proxy for that decision.
EOF
}
