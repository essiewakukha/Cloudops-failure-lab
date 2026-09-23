# Only system:serviceaccount:app:app may assume this role.
data "aws_iam_policy_document" "app_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:app:app"]
    }
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${local.name}-app"
  assume_role_policy = data.aws_iam_policy_document.app_assume.json
}

data "aws_iam_policy_document" "app" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [local.core.bucket_arn]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${local.core.bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "app" {
  name   = "s3-access"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app.json
}