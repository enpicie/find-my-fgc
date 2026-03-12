module "website" {
  source = "git::https://github.com/enpicie/tf-module-s3-cloudfront-website.git?ref=v1.1.0"

  website_name        = var.app_name
  domain_name         = var.domain_name
  acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn

  common_tags = {
    Project     = var.app_name
    Environment = var.deployment_env
  }
}
