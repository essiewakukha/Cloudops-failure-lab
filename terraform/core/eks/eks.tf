module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                             = local.name
  cluster_version                          = var.cluster_version
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true
  kms_key_deletion_window_in_days          = 7

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}