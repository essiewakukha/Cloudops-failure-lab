variable "region" {
  description = "Must match terraform/core."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  type    = string
  default = "break-fix-lab"
}

variable "cluster_version" {
  description = "null = AWS's current default. Don't pin an old version: extended support costs 6x."
  type        = string
  default     = null
}