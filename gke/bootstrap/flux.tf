# GitHub Repository for Flux
resource "github_repository" "this" {
  name       = var.repository_name
  visibility = "private"
  auto_init  = true
}

resource "tls_private_key" "this" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  title      = "flux-deploy-key"
  repository = github_repository.this.name
  key        = tls_private_key.this.public_key_openssh
  read_only  = false
}

# Generate local kubeconfig for Flux
resource "local_file" "kubeconfig" {
  content = templatefile("${path.module}/../../templates/kubeconfig.tftpl", {
    ca_data  = base64encode(module.gke_cluster.config_ca)
    endpoint = module.gke_cluster.config_host
    token    = module.gke_cluster.config_token
  })
  filename = "${path.module}/../kubeconfig"
}

# Flux Bootstrap
module "flux_bootstrap" {
  source            = "github.com/den-vasyliev/tf-fluxcd-flux-bootstrap"
  github_repository = "${var.github_owner}/${github_repository_deploy_key.this.repository}"
  private_key       = tls_private_key.this.private_key_pem
  config_path       = local_file.kubeconfig.filename
  github_token      = var.github_token
}

# Deploy Flux SA patch to enable Workload Identity
resource "github_repository_file" "flux_sa_patch" {
  repository = var.repository_name
  branch     = "main"
  file       = "clusters/flux-system/kustomize-controller-patch.yaml"
  content = templatefile("${path.module}/../../templates/flux-sa-patch.yaml.tftpl", {
    flux_sa_email = google_service_account.flux_sa.email
  })
  overwrite_on_create = true
}

# Deploy Flux decryption patch
resource "github_repository_file" "flux_decryption_patch" {
  repository          = var.repository_name
  branch              = "main"
  file                = "clusters/flux-system/flux-decryption-patch.yaml"
  content             = templatefile("${path.module}/../../templates/flux-decryption-patch.yaml.tftpl", {})
  overwrite_on_create = true
}

# Kustomization to apply the patch
resource "github_repository_file" "flux_kustomization" {
  repository          = var.repository_name
  branch              = "main"
  file                = "clusters/flux-system/kustomization.yaml"
  content             = templatefile("${path.module}/../../templates/flux-kustomization.yaml.tftpl", {})
  overwrite_on_create = true
  depends_on          = [module.flux_bootstrap]
}
