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

# The ECS module defaults this to 30. At 30 days the search log — the only
# record of what people actually search for — is on a rolling delete, and five
# months of it were already lost before anyone looked. Storage is a few cents a
# year at current volume; suppressing /health route logging would cut it ~12x more.
variable "log_retention_days" {
  description = "Days to retain backend CloudWatch logs. The ECS module defaults to 30, which silently destroys search history."
  type        = number
  default     = 365
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications. Leave empty to create the SNS topic without a subscription. AWS sends a confirmation link that must be clicked before any alarm can reach you."
  type        = string
  default     = ""
}

variable "geocode_failure_threshold" {
  description = "Geocode failures (HTTP 422) within a 15-minute window that trigger an alarm. Baseline is roughly 3 per day, so 5 in 15 minutes is well clear of noise."
  type        = number
  default     = 5
}

variable "enable_dead_canary_alarm" {
  description = "Alarm when zero searches occur in 6 hours. Catches outages that health checks miss, but is the most speculative alarm — disable if noisy."
  type        = bool
  default     = true
}
