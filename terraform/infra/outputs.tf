output "startgg_api_key_secret_arn" {
  description = "ARN of the STARTGG_API_KEY secret in Secrets Manager"
  value       = aws_secretsmanager_secret.startgg_api_key.arn
}

output "google_maps_api_key_secret_arn" {
  description = "ARN of the GOOGLE_MAPS_API_KEY secret in Secrets Manager"
  value       = aws_secretsmanager_secret.google_maps_api_key.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL for the backend image"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.backend.name
}
