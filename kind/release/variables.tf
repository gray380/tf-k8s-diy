variable "github_owner" {
  type        = string
  description = "GitHub username"
}

variable "github_token" {
  type        = string
  description = "GitHub personal access token"
}

variable "repository_name" {
  type        = string
  description = "GitHub repository name"
}

variable "TTOKEN" {
  type        = string
  description = "Telegram Bot Token"
  sensitive   = true
}
