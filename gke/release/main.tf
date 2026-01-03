resource "github_repository_file" "kbot_manifest" {
  repository = var.repository_name
  branch     = "main"
  file       = "clusters/kbot.yaml"
  content = templatefile("${path.module}/../../templates/kbot.yaml.tftpl", {
    github_owner = var.github_owner
  })
  overwrite_on_create = true
}

resource "kubernetes_secret_v1" "kbot" {
  metadata {
    name      = "kbot"
    namespace = "flux-system"
  }

  data = {
    token = var.TTOKEN
  }

  type = "Opaque"
}

resource "kubernetes_secret_v1" "ghcr_secret" {
  metadata {
    name      = "ghcr-secret"
    namespace = "flux-system"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          auth = base64encode("${var.github_owner}:${var.github_token}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}
