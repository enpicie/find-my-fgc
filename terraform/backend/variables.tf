variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "project_name" {
  description = "The base project name used for shared state lookups (e.g. find-my-fgc, without service suffix)"
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

variable "image" {
  description = "Full ECR image URI including tag (e.g., 123456789012.dkr.ecr.us-east-2.amazonaws.com/find-my-fgc/backend:abc1234)"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name for the API (e.g. api.findmyfgc.cc)"
  type        = string
}
