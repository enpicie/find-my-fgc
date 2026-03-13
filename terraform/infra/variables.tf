variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-2"
}

variable "startgg_api_key" {
  description = "Start.gg API key"
  type        = string
  sensitive   = true
}

variable "google_maps_api_key" {
  description = "Google Maps API key"
  type        = string
  sensitive   = true
}
