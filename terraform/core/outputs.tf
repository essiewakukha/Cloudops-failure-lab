output "region" { value = var.region }
output "bucket_name" { value = aws_s3_bucket.data.bucket }
output "bucket_arn" { value = aws_s3_bucket.data.arn }
output "ecr_repository_url" { value = aws_ecr_repository.app.repository_url }
output "ecr_repository_name" { value = aws_ecr_repository.app.name }
output "github_actions_role_arn" { value = try(aws_iam_role.gha[0].arn, "") }
output "github_actions_role_name" { value = try(aws_iam_role.gha[0].name, "") }