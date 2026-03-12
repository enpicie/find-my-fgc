variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "deployment_env" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-2"
}

variable "domain_name" {
  description = "Custom domain name for the site (e.g. app.example.com)"
  type        = string
}

