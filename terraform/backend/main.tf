data "aws_caller_identity" "current" {}

# Reads VPC, subnet, ECS cluster, and ALB identifiers from the shared aws-infra
# state (github.com/enpicie/aws-infra). The bucket name convention matches
# gh-action-workflow-terraform-run: "${account_id}-terraform-state".
data "terraform_remote_state" "aws_infra" {
  backend = "s3"
  config = {
    bucket = "${data.aws_caller_identity.current.account_id}-terraform-state"
    key    = "aws-infra/infra.tfstate" # Special key for infra repo
    region = var.aws_region
  }
}

data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config = {
    bucket = "${data.aws_caller_identity.current.account_id}-terraform-state"
    key    = "projects/${var.project_name}/infra.tfstate"
    region = var.aws_region
  }
}

# The HTTPS listener is created here rather than in aws-infra because aws-infra
# intentionally leaves listeners to app repos. This listener is shared by all
# services attached to the ALB — additional services add listener rules, not
# additional listeners.
resource "aws_lb_listener" "https" {
  load_balancer_arn = data.terraform_remote_state.aws_infra.outputs.alb_arn
  port              = 443
  protocol          = "HTTPS"
  # TLS 1.3 + 1.2 policy — disables older insecure protocols (TLS 1.0/1.1).
  # See: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/describe-ssl-policies.html
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = aws_acm_certificate_validation.cert.certificate_arn

  # Catch-all for requests that don't match any listener rule.
  # Individual services attach rules (e.g. host-header match) via the module below.
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

module "service" {
  source = "git::https://github.com/enpicie/tf-module-ecs-alb-service.git?ref=v1.2.0"

  name                  = "${var.app_name}-${var.deployment_env}"
  image                 = var.image
  vpc_id                = data.terraform_remote_state.aws_infra.outputs.vpc_id
  subnet_ids            = data.terraform_remote_state.aws_infra.outputs.private_subnet_ids
  cluster_arn           = data.terraform_remote_state.aws_infra.outputs.ecs_cluster_arn
  listener_arn          = aws_lb_listener.https.arn
  alb_security_group_id = data.terraform_remote_state.aws_infra.outputs.alb_security_group_id

  # Route requests to this service only when the Host header matches the API
  # domain. Other host headers fall through to the listener's default 404 action.
  listener_rule_host_headers = [var.domain_name]

  # Vapor exposes GET /health by default — no custom route needed.
  health_check_path = "/health"
  # Tasks are in private subnets with a NAT Gateway (defined in aws-infra),
  # so they don't need a public IP for outbound traffic (ECR pulls, etc.).
  assign_public_ip = false

  secrets = [
    {
      name      = "STARTGG_API_KEY"
      valueFrom = data.terraform_remote_state.bootstrap.outputs.startgg_api_key_secret_arn
    },
    {
      name      = "GOOGLE_MAPS_API_KEY"
      valueFrom = data.terraform_remote_state.bootstrap.outputs.google_maps_api_key_secret_arn
    }
  ]

  tags = {
    Project     = var.app_name
    Environment = var.deployment_env
  }
}
