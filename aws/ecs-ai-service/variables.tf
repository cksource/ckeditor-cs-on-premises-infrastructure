variable "license_key" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "docker_token" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "environments_management_secret_key" {
  type      = string
  sensitive = true
  nullable  = false
}

# Passed to the container as the `PROVIDERS` environment variable. Named
# `providers_config` because `providers` is a reserved argument of the
# `module` block.
variable "providers_config" {
  type      = string
  sensitive = true
  nullable  = false
}

# Passed to the container as the `MODELS` environment variable. Leave it empty
# to use the default model list of every configured provider.
variable "models_config" {
  type     = string
  nullable = false
  default  = ""
}

variable "image_version" {
  type     = string
  nullable = false
  default  = "latest"
}
