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

variable "image_version" {
  type     = string
  nullable = false
}
