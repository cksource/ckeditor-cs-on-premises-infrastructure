resource "kubernetes_namespace" "ckeditor_cs" {
  metadata {
    annotations = {
      name = local.namespace
    }

    name = local.namespace
  }
}

resource "kubernetes_secret" "container_registry" {
  metadata {
    name      = "docker-cke-cs-com"
    namespace = local.namespace
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.docker_host) = {
          auth = base64encode("${var.docker_username}:${var.docker_token}")
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}
