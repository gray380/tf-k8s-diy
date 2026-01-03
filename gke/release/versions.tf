terraform {
  backend "gcs" {
    bucket = "gray380-devops101"
    prefix = "terraform/state/gke-flux-release"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.14"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}
