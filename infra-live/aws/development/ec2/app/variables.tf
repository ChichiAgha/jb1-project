variable "vpc_remote_state" {
  description = "Remote state configuration for the VPC stack."
  type = object({
    bucket = string
    key    = string
    region = string
  })
}

variable "app_stack" {
  description = "Development app infrastructure configuration object."
  type = object({
    aws_region  = string
    name_prefix = string
    security = object({
      alb_ingress_cidrs = list(string)
      app_port          = optional(number, 80)
      ssh_ingress_cidrs = optional(list(string), [])
    })
    load_balancer = object({
      internal          = optional(bool, false)
      listener_port     = optional(number, 80)
      target_port       = optional(number, 80)
      health_check_path = optional(string, "/api/health")
      certificate_arn   = optional(string, null)
    })
    compute = object({
      instance_type               = string
      desired_capacity            = number
      min_size                    = number
      max_size                    = number
      key_name                    = optional(string, null)
      associate_public_ip_address = optional(bool, false)
      dockerhub_username          = string
      image_tag                   = string
      compose_project_name        = optional(string, "taskapp")
      root_volume_size            = optional(number, 30)
      backend_env = object({
        app_env     = optional(string, "production")
        app_debug   = optional(string, "false")
        db_host     = string
        db_port     = string
        db_database = string
        db_username = string
        db_password = string
      })
    })
    tags = optional(map(string), {})
  })
}
