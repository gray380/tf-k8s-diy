terraform {
  backend "gcs" {
    bucket = "gray380-devops101"
    prefix = "terraform/state/gke-flux-bootstrap"
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
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23"
    }
  }
}
