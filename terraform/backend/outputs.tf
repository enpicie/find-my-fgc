output "ecs_service_name" {
  description = "ECS service name"
  value       = module.service.ecs_service_name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = module.service.log_group_name
}

output "alb_dns_name" {
  description = "ALB DNS name (use for Route53 alias or Cloudflare CNAME)"
  value       = data.terraform_remote_state.aws_infra.outputs.alb_dns_name
}
