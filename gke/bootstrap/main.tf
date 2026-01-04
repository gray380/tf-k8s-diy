# GKE Cluster
module "gke_cluster" {
  source         = "github.com/gray380/tf-google-gke-cluster"
  GOOGLE_PROJECT = var.GOOGLE_PROJECT
  GOOGLE_REGION  = var.GOOGLE_REGION
  GKE_NUM_NODES  = var.GKE_NUM_NODES
}

module "enabled_google_apis" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.5"

  project_id                  = var.GOOGLE_PROJECT
  disable_services_on_destroy = false

  activate_apis = [
    "cloudkms.googleapis.com",
    "secretmanager.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

resource "google_kms_key_ring" "key_ring" {
  name       = "sops-key-ring"
  location   = "global"
  project    = var.GOOGLE_PROJECT
  depends_on = [module.enabled_google_apis]
}

resource "google_kms_crypto_key" "key" {
  name     = "sops-key"
  key_ring = google_kms_key_ring.key_ring.id
}

resource "google_iam_workload_identity_pool" "github" {
  provider                  = google-beta
  workload_identity_pool_id = "github-pool"
  project                   = var.GOOGLE_PROJECT
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "github" {
  provider                           = google-beta
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  project                            = var.GOOGLE_PROJECT
  display_name                       = "GitHub Actions Provider"
  description                        = "OIDC Provider for GitHub Actions"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "gha_sa" {
  account_id   = "gha-sa"
  display_name = "GitHub Actions Service Account"
  project      = var.GOOGLE_PROJECT
}

resource "google_service_account" "flux_sa" {
  account_id   = "flux-sa"
  display_name = "Flux Service Account"
  project      = var.GOOGLE_PROJECT
}

resource "google_project_iam_member" "gha_secret_accessor" {
  project = var.GOOGLE_PROJECT
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.gha_sa.email}"
}

resource "google_kms_crypto_key_iam_member" "gha_encrypter" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypter"
  member        = "serviceAccount:${google_service_account.gha_sa.email}"
}

resource "google_kms_crypto_key_iam_member" "flux_decrypter" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyDecrypter"
  member        = "serviceAccount:${google_service_account.flux_sa.email}"
}

# Allow GitHub Actions to impersonate gha_sa
resource "google_service_account_iam_member" "gha_wif_binding" {
  service_account_id = google_service_account.gha_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_owner}/${var.repository_name}"
}

# Allow Flux KSA to impersonate flux_sa
resource "google_service_account_iam_member" "flux_wif_binding" {
  service_account_id = google_service_account.flux_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.GOOGLE_PROJECT}.svc.id.goog[flux-system/kustomize-controller]"
}

# Flux Annotations
resource "kubernetes_annotations" "flux_kms" {
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = "kustomize-controller"
    namespace = "flux-system"
  }
  annotations = {
    "iam.gke.io/gcp-service-account" = google_service_account.flux_sa.email
  }
  depends_on = [module.flux_bootstrap]
}

output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}

output "gha_service_account" {
  value = google_service_account.gha_sa.email
}
