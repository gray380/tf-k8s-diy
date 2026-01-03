# Use the cluster data source to get credentials for the kubernetes provider
data "google_container_cluster" "main" {
  name     = "main"
  location = var.GOOGLE_REGION
}

data "google_client_config" "current" {}
