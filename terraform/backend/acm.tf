resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Project     = var.app_name
    Environment = var.deployment_env
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
  # No validation_record_fqdns — DNS CNAME record is added manually in Cloudflare
  # after the cert is first created. Terraform will wait here until ACM confirms
  # the domain is validated. Subsequent applies skip this wait once already valid.
}
