variable "github_owner" {
  type        = string
  description = "GitHub owner"
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub token"
}

variable "repository_name" {
  type        = string
  description = "GitHub repository name"
}

variable "TTOKEN" {
  type        = string
  sensitive   = true
  description = "Telegram Bot Token"
}

variable "target_namespace" {
  type        = string
  default     = "demo"
  description = "Target namespace for the application"
}

variable "image_arch" {
  type        = string
  default     = "amd64"
  description = "Image architecture (amd64 or arm64)"
}
