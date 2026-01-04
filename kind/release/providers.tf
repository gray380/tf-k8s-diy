provider "github" {
  owner = var.github_owner
  token = var.github_token
}

provider "kubernetes" {
  config_path = "${path.module}/../kubeconfig"
}
