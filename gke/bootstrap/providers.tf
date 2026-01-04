provider "google" {
  project = var.GOOGLE_PROJECT
  region  = var.GOOGLE_REGION
}

provider "github" {
  owner = var.github_owner
  token = var.github_token
}

provider "kubernetes" {
  host                   = "https://${module.gke_cluster.config_host}"
  token                  = module.gke_cluster.config_token
  cluster_ca_certificate = base64decode(module.gke_cluster.config_ca)
}
