resource "tls_private_key" "this" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository" "this" {
  name       = var.repository_name
  visibility = "private"
  auto_init  = true
}

resource "github_repository_deploy_key" "this" {
  title      = "flux-deploy-key"
  repository = github_repository.this.name
  key        = tls_private_key.this.public_key_openssh
  read_only  = false
}

module "flux_bootstrap" {
  source            = "github.com/den-vasyliev/tf-fluxcd-flux-bootstrap"
  github_repository = "${var.github_owner}/${var.repository_name}"
  private_key       = tls_private_key.this.private_key_pem
  config_path       = kind_cluster.this.kubeconfig_path
  github_token      = var.github_token
}
