output "alb_dns_name" {
  value = module.app.alb_dns_name
}

output "target_group_arn" {
  value = module.app.target_group_arn
}

output "autoscaling_group_name" {
  value = module.app.autoscaling_group_name
}
