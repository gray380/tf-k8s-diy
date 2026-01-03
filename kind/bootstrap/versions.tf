terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.8.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.2"
    }
  }
}
