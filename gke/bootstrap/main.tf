# GKE Cluster
module "gke_cluster" {
  source         = "github.com/gray380/tf-google-gke-cluster"
  GOOGLE_PROJECT = var.GOOGLE_PROJECT
  GOOGLE_REGION  = var.GOOGLE_REGION
  GKE_NUM_NODES  = var.GKE_NUM_NODES
}
