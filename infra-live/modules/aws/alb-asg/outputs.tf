output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "Application Load Balancer DNS name."
}

output "target_group_arn" {
  value       = aws_lb_target_group.app.arn
  description = "Target group ARN."
}

output "autoscaling_group_name" {
  value       = aws_autoscaling_group.app.name
  description = "Auto Scaling Group name."
}
