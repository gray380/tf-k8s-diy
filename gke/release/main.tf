resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.target_namespace
  }
}

resource "github_repository_file" "kbot_manifest" {
  repository = var.repository_name
  branch     = "main"
  file       = "clusters/kbot.yaml"
  content = templatefile("${path.module}/../../templates/kbot.yaml.tftpl", {
    github_owner     = var.github_owner
    target_namespace = var.target_namespace
    image_arch       = var.image_arch
  })
  overwrite_on_create = true
}

resource "github_repository_file" "kbot_secrets" {
  repository = var.repository_name
  branch     = "main"
  file       = "clusters/secrets.yaml"
  content = templatefile("${path.module}/../../templates/secrets.yaml.tftpl", {
    target_namespace = var.target_namespace
  })
  overwrite_on_create = true
}


resource "kubernetes_secret_v1" "ghcr_secret" {
  metadata {
    name      = "ghcr-secret"
    namespace = kubernetes_namespace_v1.this.metadata[0].name
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
