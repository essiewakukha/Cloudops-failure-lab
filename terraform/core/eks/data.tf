# Reads bucket/ECR details from the always-on core stack.
data "terraform_remote_state" "core" {
  backend = "local"
  config = {
    path = "${path.module}/../core/terraform.tfstate"
  }
}

data "aws_availability_zones" "available" {
  state            = "available"
  exclude_zone_ids = ["use1-az3"] # no EKS control plane support in this us-east-1 AZ
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name = var.name
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
  core = data.terraform_remote_state.core.outputs
}