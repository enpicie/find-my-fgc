output "url" {
  value = module.website.cloudfront_domain_name
}

output "bucket_name" {
  value = module.website.bucket_name
}
