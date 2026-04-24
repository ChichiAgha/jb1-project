output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks_control_plane.cluster_id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks_control_plane.cluster_name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks_control_plane.cluster_arn
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = module.eks_control_plane.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster"
  value       = module.eks_control_plane.cluster_certificate_authority_data
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider"
  value       = module.eks_control_plane.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "The URL of the OIDC provider"
  value       = module.eks_control_plane.oidc_provider_url
}

output "node_groups" {
  description = "Map of all EKS node groups"
  value       = module.eks_node_group.node_groups
}

output "node_group_ids" {
  description = "Map of node group IDs"
  value       = module.eks_node_group.node_group_ids
}

output "node_group_names" {
  description = "Map of node group names"
  value       = module.eks_node_group.node_group_names
}

output "node_role_arn" {
  description = "The ARN of the IAM role used by the node groups"
  value       = module.eks_node_group.node_role_arn
}

output "kubeconfig_command" {
  description = "The command to update kubeconfig"
  value       = var.enable_aws_auth ? module.aws_auth_config[0].kubeconfig_command : null
}

output "storage_classes" {
  description = "Map of created storage classes"
  value       = var.enable_storage_class ? module.eks_storage_class[0].storage_classes : null
}

output "default_storage_class" {
  description = "The default storage class name"
  value       = var.enable_storage_class ? module.eks_storage_class[0].default_storage_class : null
}
