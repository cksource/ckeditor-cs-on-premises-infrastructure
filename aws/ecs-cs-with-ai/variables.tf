# The Collaboration Server and CKEditor AI Service are licensed separately, so
# each one needs its own license key and its own registry download token. Both
# are found in the CKEditor Customer Portal, on their respective subscription
# pages.
variable "cs_license_key" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "ai_license_key" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "cs_docker_token" {
  type      = string
  sensitive = true
  nullable  = false
}

variable "ai_docker_token" {
  type      = string
  sensitive = true
  nullable  = false
}

# Shared by both services - it is the password to the single management panel
# that configures them once they run on one data layer.
variable "environments_management_secret_key" {
  type      = string
  sensitive = true
  nullable  = false
}

# Passed to the AI Service as the `PROVIDERS` environment variable. Named
# `providers_config` because `providers` is a reserved argument of the `module`
# block.
variable "providers_config" {
  type      = string
  sensitive = true
  nullable  = false
}

# Passed to the AI Service as the `MODELS` environment variable. Leave it empty
# to use the default model list of every configured provider.
variable "models_config" {
  type     = string
  nullable = false
  default  = ""
}

# Compatible mode requires Collaboration Server 5.0.0 or newer, and the two
# services are released together - keep these two versions in step.
variable "cs_image_version" {
  type     = string
  nullable = false
  default  = "latest"
}

variable "ai_image_version" {
  type     = string
  nullable = false
  default  = "latest"
}
