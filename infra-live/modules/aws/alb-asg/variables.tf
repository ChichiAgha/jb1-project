variable "network" {
  description = "App networking context."
  type = object({
    name_prefix        = string
    vpc_id             = string
    public_subnet_ids  = list(string)
    private_subnet_ids = list(string)
  })
}

variable "security" {
  description = "Security configuration."
  type = object({
    alb_ingress_cidrs = list(string)
    app_port          = optional(number, 80)
    ssh_ingress_cidrs = optional(list(string), [])
  })
}

variable "load_balancer" {
  description = "ALB and target group configuration."
  type = object({
    internal          = optional(bool, false)
    listener_port     = optional(number, 80)
    target_port       = optional(number, 80)
    health_check_path = optional(string, "/api/health")
    certificate_arn   = optional(string, null)
  })
}

variable "compute" {
  description = "Launch template and Auto Scaling Group configuration."
  type = object({
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
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
