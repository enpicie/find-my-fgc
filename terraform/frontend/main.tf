module "website" {
  source = "git::https://github.com/enpicie/tf-module-s3-cloudfront-website.git?ref=v1.0.0"

  website_name = var.app_name
  source_files = "./dist" # Vite React standard output directory

  common_tags = {
    Project     = var.app_name
    Environment = var.deployment_env
  }
}
