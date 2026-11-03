# Single CloudWatch dashboard for at-a-glance usage. Everything here reads data
# AWS already collects (ALB/CloudFront metrics, container logs) — no app changes.
locals {
  log_group = module.service.log_group_name

  # CloudWatch dimensions want the ARN suffix, not the full ARN:
  #   TargetGroup  = "targetgroup/<name>/<id>"
  #   LoadBalancer = "app/<name>/<id>"
  target_group_dimension  = split(":", module.service.target_group_arn)[5]
  load_balancer_dimension = trimprefix(split(":", data.terraform_remote_state.aws_infra.outputs.alb_arn)[5], "loadbalancer/")

  # CloudFront metrics only exist in us-east-1 with Region=Global.
  # Counts every file served (HTML, JS, images), so it's a traffic signal, not page views.
  cloudfront_widgets = var.cloudfront_distribution_id == "" ? [] : [
    {
      type   = "metric"
      x      = 0
      y      = 1
      width  = 12
      height = 6
      properties = {
        title   = "Site traffic (CloudFront requests / day)"
        region  = "us-east-1"
        view    = "timeSeries"
        stat    = "Sum"
        period  = 86400
        metrics = [["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id, "Region", "Global"]]
      }
    }
  ]

  backend_widgets = [
    {
      type   = "text"
      x      = 0
      y      = 0
      width  = 24
      height = 1
      properties = {
        markdown = "## ${var.project_name} usage (${var.deployment_env})"
      }
    },
    {
      type   = "log"
      x      = 12
      y      = 1
      width  = 12
      height = 6
      properties = {
        title  = "Searches / day"
        region = var.aws_region
        view   = "bar"
        query  = <<-EOT
          SOURCE '${local.log_group}'
          | filter @message like "POST /tournaments complete"
          | stats count(*) as searches by bin(1d)
        EOT
      }
    },
    {
      type   = "log"
      x      = 0
      y      = 7
      width  = 12
      height = 8
      properties = {
        title  = "Top search locations"
        region = var.aws_region
        view   = "table"
        query  = <<-EOT
          SOURCE '${local.log_group}'
          | filter @message like "POST /tournaments" and @message like "query:"
          | parse @message /query: "?(?<location>[^",\]]+)/
          | stats count(*) as searches by location
          | sort searches desc
          | limit 20
        EOT
      }
    },
    {
      type   = "metric"
      x      = 12
      y      = 7
      width  = 12
      height = 8
      properties = {
        title  = "API requests & errors (hourly)"
        region = var.aws_region
        view   = "timeSeries"
        stat   = "Sum"
        period = 3600
        metrics = [
          ["AWS/ApplicationELB", "RequestCount", "TargetGroup", local.target_group_dimension, "LoadBalancer", local.load_balancer_dimension, { label = "Requests" }],
          ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "TargetGroup", local.target_group_dimension, "LoadBalancer", local.load_balancer_dimension, { label = "5xx errors" }],
          ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "TargetGroup", local.target_group_dimension, "LoadBalancer", local.load_balancer_dimension, { label = "4xx errors" }],
        ]
      }
    },
  ]
}

resource "aws_cloudwatch_dashboard" "usage" {
  dashboard_name = "${var.project_name}-${var.deployment_env}-usage"
  dashboard_body = jsonencode({
    start   = "-P30D"
    widgets = concat(local.backend_widgets, local.cloudfront_widgets)
  })
}
