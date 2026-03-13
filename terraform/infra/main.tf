resource "aws_secretsmanager_secret" "startgg_api_key" {
  name        = "${var.app_name}/STARTGG_API_KEY"
  description = "Start.gg API key for the backend service"
}

resource "aws_secretsmanager_secret_version" "startgg_api_key" {
  secret_id     = aws_secretsmanager_secret.startgg_api_key.id
  secret_string = var.startgg_api_key
}

resource "aws_secretsmanager_secret" "gemini_api_key" {
  name        = "${var.app_name}/GEMINI_API_KEY"
  description = "Google Gemini API key for the backend service"
}

resource "aws_secretsmanager_secret_version" "gemini_api_key" {
  secret_id     = aws_secretsmanager_secret.gemini_api_key.id
  secret_string = var.gemini_api_key
}


resource "aws_ecr_repository" "backend" {
  name                 = "${var.app_name}/backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
