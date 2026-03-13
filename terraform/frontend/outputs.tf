output "url" {
  value = module.website.cloudfront_domain_name
}

output "bucket_name" {
  value = module.website.bucket_name
}

output "distribution_id" {
  value = split("/", module.website.cloudfront_distribution_arn)[1]
}
