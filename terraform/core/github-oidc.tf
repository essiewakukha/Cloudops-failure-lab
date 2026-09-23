# GitHub Actions → AWS with short-lived OIDC credentials (no stored keys).
# If your account already has this OIDC provider, import it or remove the resource.
locals {
  gha = var.github_repo != "" ? 1 : 0
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = local.gha
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "gha_assume" {
  count = local.gha
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "gha" {
  count              = local.gha
  name               = "${var.name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.gha_assume[0].json
}

data "aws_iam_policy_document" "gha" {
  count = local.gha
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload", "ecr:PutImage", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer",
    ]
    resources = [aws_ecr_repository.app.arn]
  }
}

resource "aws_iam_role_policy" "gha" {
  count  = local.gha
  name   = "ecr-push"
  role   = aws_iam_role.gha[0].id
  policy = data.aws_iam_policy_document.gha[0].json
}