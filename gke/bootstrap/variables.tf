variable "GOOGLE_PROJECT" {
  type        = string
  description = "GCP Project ID"
}

variable "GOOGLE_REGION" {
  type        = string
  description = "GCP Region"
}

variable "GKE_NUM_NODES" {
  type        = number
  description = "Number of GKE nodes"
}

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
