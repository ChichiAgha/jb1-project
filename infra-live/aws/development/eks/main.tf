module "eks_control_plane" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/eks-controle-plane?ref=develop"

  eks = merge(var.eks, {
    subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
    tags       = local.tags
  })
}

module "eks_node_group" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/eks-nodes-group?ref=develop"

  eks_node_group = merge(var.eks_node_group, {
    aws_region   = var.eks.aws_region
    cluster_name = module.eks_control_plane.cluster_name
    subnet_ids   = data.terraform_remote_state.vpc.outputs.private_subnets
    tags         = local.tags
  })

  depends_on = [module.eks_control_plane]
}

module "aws_auth_config" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/aws-auth-config?ref=develop"
  count  = var.enable_aws_auth ? 1 : 0

  aws_auth = merge(var.aws_auth, {
    aws_region   = var.eks.aws_region
    cluster_name = module.eks_control_plane.cluster_name
    tags         = local.tags
  })

  depends_on = [module.eks_control_plane]
}

module "eks_storage_class" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/eks-storage-class?ref=develop"
  count  = var.enable_storage_class ? 1 : 0

  eks_storage_class = merge(var.eks_storage_class, {
    aws_region   = var.eks.aws_region
    cluster_name = module.eks_control_plane.cluster_name
    tags         = local.tags
  })

  depends_on = [module.eks_node_group]
}

module "eks_cluster_autoscaler" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/eks-cluster-autoscaler?ref=develop"
  count  = var.enable_cluster_autoscaler ? 1 : 0

  eks_cluster_autoscaler = merge(var.eks_cluster_autoscaler, {
    aws_region   = var.eks.aws_region
    cluster_name = module.eks_control_plane.cluster_name
    tags         = local.tags
  })

  depends_on = [module.eks_node_group, module.eks_load_balancer_controller]
}

module "eks_ebs_csi_driver" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/eks-ebs-csi-driver?ref=develop"
  count  = var.enable_ebs_csi_driver ? 1 : 0

  eks_ebs_csi_driver = merge(var.eks_ebs_csi_driver, {
    aws_region   = var.eks.aws_region
    cluster_name = module.eks_control_plane.cluster_name
    tags         = local.tags
  })

  depends_on = [module.eks_node_group, module.eks_load_balancer_controller]
}

module "eks_external_dns" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/eks-external-dns?ref=develop"
  count  = var.enable_external_dns ? 1 : 0

  eks_external_dns = merge(var.eks_external_dns, {
    aws_region   = var.eks.aws_region
    cluster_name = module.eks_control_plane.cluster_name
    tags         = local.tags
  })

  depends_on = [module.eks_node_group, module.eks_load_balancer_controller]
}

module "eks_load_balancer_controller" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/eks-load-balancer-controller?ref=develop"
  count  = var.enable_load_balancer_controller ? 1 : 0

  eks_load_balancer_controller = merge(var.eks_load_balancer_controller, {
    aws_region   = var.eks.aws_region
    cluster_name = module.eks_control_plane.cluster_name
    vpc_id       = data.terraform_remote_state.vpc.outputs.vpc_id
    tags         = local.tags
  })

  depends_on = [module.eks_node_group]
}

module "eks_metrics_server" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/eks-metrics-server?ref=develop"
  count  = var.enable_metrics_server ? 1 : 0

  eks_metrics_server = merge(var.eks_metrics_server, {
    aws_region   = var.eks.aws_region
    cluster_name = module.eks_control_plane.cluster_name
    tags         = local.tags
  })

  depends_on = [module.eks_node_group, module.eks_load_balancer_controller]
}

module "eks_namespaces" {
  source = "git::https://git.edusuc.net/WEBFORX/Plateng-terraform-modules.git//aws/eks-namespaces?ref=develop"
  count  = var.enable_namespaces ? 1 : 0

  eks_namespaces = merge(var.eks_namespaces, {
    aws_region   = var.eks.aws_region
    cluster_name = module.eks_control_plane.cluster_name
    tags         = local.tags
  })

  depends_on = [module.eks_node_group, module.eks_load_balancer_controller]
}
