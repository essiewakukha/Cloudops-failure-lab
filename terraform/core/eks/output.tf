output "region" { value = var.region }
output "cluster_name" { value = module.eks.cluster_name }
output "app_role_arn" { value = aws_iam_role.app.arn }
output "private_route_table_ids" { value = module.vpc.private_route_table_ids }