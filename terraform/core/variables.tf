variable "region" {
  type    = string
  default = "us-east-1"
}

variable "name" {
  type    = string
  default = "Cloudops-failure-lab"
}

variable "github_repo" {
  description = "Optional 'owner/repo' to enable GitHub Actions OIDC. Leave empty to skip."
  type        = string
  default     = "https://github.com/essiewakukha/Cloudops-failure-lab"
}