resource "helm_release" "ckeditor-cs" {
  name       = "ckeditor-cs"
  namespace  = local.namespace
  repository = "${path.module}/../../../kubernetes/helm"
  chart      = "ckeditor-cs"

  values = [
    file("${path.module}/../../../kubernetes/helm/ckeditor-cs/values.yaml")
  ]

  set {
    name  = "server.replicaCount"
    value = 2
  }

  set {
    name  = "server.ingress.enabled"
    value = true
  }

  set {
    name  = "server.ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "azure/application-gateway"
  }

  set {
    name  = "server.ingress.hosts[0].host"
    value = ""
  }

  set {
    name  = "server.ingresshosts[0].paths[0].path"
    value = "/"
  }

  set {
    name  = "server.secret.data.LICENSE_KEY"
    value = var.license_key
  }

  set {
    name  = "server.secret.data.ENVIRONMENTS_MANAGEMENT_SECRET_KEY"
    value = var.environments_management_secret_key
  }

  set {
    name  = "server.secret.data.DATABASE_HOST"
    value = var.mysql_host
  }

  set {
    name  = "server.secret.data.DATABASE_USER"
    value = var.mysql_user
  }

  set {
    name  = "server.secret.data.DATABASE_PASSWORD"
    value = var.mysql_password
  }

  set {
    name  = "server.secret.data.DATABASE_DATABASE"
    value = var.mysql_database
  }

  set {
    name  = "server.secret.data.DATABASE_SSL_CA"
    value = <<EOT
-----BEGIN CERTIFICATE-----
MIIDrzCCApegAwIBAgIQCDvgVpBCRrGhdWrJWZHHSjANBgkqhkiG9w0BAQUFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0wNjExMTAwMDAwMDBaFw0zMTExMTAwMDAwMDBaMGExCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
b20xIDAeBgNVBAMTF0RpZ2lDZXJ0IEdsb2JhbCBSb290IENBMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4jvhEXLeqKTTo1eqUKKPC3eQyaKl7hLOllsB
CSDMAZOnTjC3U/dDxGkAV53ijSLdhwZAAIEJzs4bg7/fzTtxRuLWZscFs3YnFo97
nh6Vfe63SKMI2tavegw5BmV/Sl0fvBf4q77uKNd0f3p4mVmFaG5cIzJLv07A6Fpt
43C/dxC//AH2hdmoRBBYMql1GNXRor5H4idq9Joz+EkIYIvUX7Q6hL+hqkpMfT7P
T19sdl6gSzeRntwi5m3OFBqOasv+zbMUZBfHWymeMr/y7vrTC0LUq7dBMtoM1O/4
gdW7jVg/tRvoSSiicNoxBN33shbyTApOB6jtSj1etX+jkMOvJwIDAQABo2MwYTAO
BgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUA95QNVbR
TLtm8KPiGxvDl7I90VUwHwYDVR0jBBgwFoAUA95QNVbRTLtm8KPiGxvDl7I90VUw
DQYJKoZIhvcNAQEFBQADggEBAMucN6pIExIK+t1EnE9SsPTfrgT1eXkIoyQY/Esr
hMAtudXH/vTBH1jLuG2cenTnmCmrEbXjcKChzUyImZOMkXDiqw8cvpOp/2PV5Adg
06O/nVsJ8dWO41P0jmP6P6fbtGbfYmbW0W5BjfIttep3Sp+dWOIrWcBAI+0tKIJF
PnlUkiaY4IBIqDfv8NZ5YBberOgOzW6sRBc4L0na4UU+Krk2U886UAb3LujEV0ls
YSEY1QSteDwsOoBrp+uvFRTp2InBuThs4pFsiv9kuXclVzDAGySj4dzp30d8tbQk
CAUw7C29C79Fv1C5qfPrmAESrciIxpg0X40KPMbp1ZWVbd4=
-----END CERTIFICATE-----
EOT
  }

  set {
    name  = "server.secret.data.REDIS_HOST"
    value = var.redis_host
  }

  set {
    name  = "server.secret.data.REDIS_PASSWORD"
    value = var.redis_password
  }

  set {
    name  = "server.secret.data.STORAGE_DRIVER"
    value = "azure"
  }

  set {
    name  = "server.secret.data.STORAGE_ACCOUNT_NAME"
    value = var.storage_account_name
  }

  set {
    name  = "server.secret.data.STORAGE_ACCOUNT_KEY"
    value = var.storage_account_key
  }

  set {
    name  = "server.secret.data.STORAGE_CONTAINER"
    value = var.storage_container
  }

  depends_on = [kubernetes_secret.container_registry]
  timeout    = 300
}
