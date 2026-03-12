module "website" {
  source = "git::https://github.com/enpicie/tf-module-s3-cloudfront-website.git?ref=v1.0.0"

  website_name        = var.app_name
  source_files        = "./dist" # Vite React standard output directory
  domain_name         = var.domain_name
  acm_certificate_arn = aws_acm_certificate_validation.cert.certificate_arn

  common_tags = {
    Project     = var.app_name
    Environment = var.deployment_env
  }
}
