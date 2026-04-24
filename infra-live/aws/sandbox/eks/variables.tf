variable "eks" {
  type = object({
    aws_region              = string
    cluster_name            = string
    eks_version             = string
    endpoint_private_access = optional(bool, true)
    endpoint_public_access  = optional(bool, true)
    enable_oidc_provider    = optional(bool, true)
    enable_cluster_logging  = optional(bool, false)
    name_prefix             = string
    tags                    = optional(map(string), {})
  })
  description = "EKS control plane configuration object"
}

variable "eks_node_group" {
  type = object({
    eks_version = string
    node_groups = map(object({
      instance_types = list(string)
      capacity_type  = string
      ami_type       = string
      disk_size      = number
      scaling_config = object({
        desired_size = number
        min_size     = number
        max_size     = number
      })
      enable_labels = optional(bool, false)
      labels        = optional(map(string), {})
      enable_taints = optional(bool, false)
      taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })), [])
    }))
    ec2_ssh_key               = optional(string, null)
    enable_cluster_autoscaler = optional(bool, true)
    name_prefix               = string
    tags                      = optional(map(string), {})
  })
  description = "EKS node group configuration object"
}

variable "enable_aws_auth" {
  type        = bool
  default     = true
  description = "Enable AWS auth config module"
}

variable "aws_auth" {
  type = object({
    name_prefix = string
    tags        = optional(map(string), {})
  })
  default = {
    name_prefix = ""
  }
  description = "AWS auth configuration object"
}

variable "enable_storage_class" {
  type        = bool
  default     = true
  description = "Enable EKS storage class module"
}

variable "eks_storage_class" {
  type = object({
    storage_classes = optional(map(object({
      is_default             = optional(bool, false)
      allow_volume_expansion = optional(bool, true)
      volume_binding_mode    = optional(string, "WaitForFirstConsumer")
      reclaim_policy         = optional(string, "Retain")
      storage_provisioner    = optional(string, "ebs.csi.aws.com")
      parameters = optional(object({
        type       = optional(string, "gp3")
        fsType     = optional(string, "ext4")
        encrypted  = optional(string, "true")
        iops       = optional(string, null)
        throughput = optional(string, null)
      }), {})
    })), {})
    name_prefix = string
    tags        = optional(map(string), {})
  })
  default = {
    name_prefix = ""
  }
  description = "EKS storage class configuration object"
}

variable "enable_cluster_autoscaler" {
  type        = bool
  default     = false
  description = "Enable EKS cluster autoscaler module"
}

variable "eks_cluster_autoscaler" {
  type = object({
    namespace                  = optional(string, "kube-system")
    service_account_name       = optional(string, "cluster-autoscaler-sa")
    chart_version              = optional(string, null)
    scale_down_delay_after_add = optional(string, "10m")
    scale_down_unneeded_time   = optional(string, "10m")
    name_prefix                = string
    tags                       = optional(map(string), {})
  })
  default = {
    name_prefix = ""
  }
  description = "EKS cluster autoscaler configuration object"
}

variable "enable_ebs_csi_driver" {
  type        = bool
  default     = false
  description = "Enable EKS EBS CSI driver module"
}

variable "eks_ebs_csi_driver" {
  type = object({
    namespace            = optional(string, "kube-system")
    service_account_name = optional(string, "ebs-csi-controller-sa")
    chart_version        = optional(string, null)
    create_storage_class = optional(bool, true)
    storage_class = optional(object({
      name                   = optional(string, "ebs-gp3")
      is_default             = optional(bool, false)
      volume_type            = optional(string, "gp3")
      fs_type                = optional(string, "ext4")
      encrypted              = optional(bool, true)
      reclaim_policy         = optional(string, "Delete")
      volume_binding_mode    = optional(string, "WaitForFirstConsumer")
      allow_volume_expansion = optional(bool, true)
    }), {})
    name_prefix = string
    tags        = optional(map(string), {})
  })
  default = {
    name_prefix = ""
  }
  description = "EKS EBS CSI driver configuration object"
}

variable "enable_external_dns" {
  type        = bool
  default     = false
  description = "Enable EKS external DNS module"
}

variable "eks_external_dns" {
  type = object({
    namespace            = optional(string, "kube-system")
    service_account_name = optional(string, "external-dns-sa")
    chart_version        = optional(string, null)
    domain_filters       = optional(list(string), [])
    policy               = optional(string, "sync")
    txt_owner_id         = optional(string, null)
    name_prefix          = string
    tags                 = optional(map(string), {})
  })
  default = {
    name_prefix = ""
  }
  description = "EKS external DNS configuration object"
}

variable "enable_load_balancer_controller" {
  type        = bool
  default     = false
  description = "Enable EKS AWS Load Balancer Controller module"
}

variable "eks_load_balancer_controller" {
  type = object({
    namespace            = optional(string, "kube-system")
    service_account_name = optional(string, "aws-load-balancer-controller-sa")
    chart_version        = optional(string, null)
    name_prefix          = string
    tags                 = optional(map(string), {})
  })
  default = {
    name_prefix = ""
  }
  description = "EKS AWS Load Balancer Controller configuration object"
}

variable "enable_metrics_server" {
  type        = bool
  default     = false
  description = "Enable EKS metrics server module"
}

variable "eks_metrics_server" {
  type = object({
    namespace     = optional(string, "kube-system")
    chart_version = optional(string, null)
    replicas      = optional(number, 1)
    name_prefix   = string
    tags          = optional(map(string), {})
  })
  default = {
    name_prefix = ""
  }
  description = "EKS metrics server configuration object"
}

variable "enable_namespaces" {
  type        = bool
  default     = false
  description = "Enable EKS namespaces module"
}

variable "eks_namespaces" {
  type = object({
    namespaces  = optional(list(string), [])
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
    name_prefix = string
    tags        = optional(map(string), {})
  })
  default = {
    name_prefix = ""
  }
  description = "EKS namespaces configuration object"
}
