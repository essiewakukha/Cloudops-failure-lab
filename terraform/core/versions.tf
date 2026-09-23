terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.95" }
  }
  # Local state for the lab. terraform/eks reads it via terraform_remote_state.
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { Project = var.name, Stack = "core", ManagedBy = "terraform" }
  }
}