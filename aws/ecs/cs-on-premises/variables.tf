variable "az_count" {
  type    = number
  default = 3
}

variable "aws_region" {
  type = string
}

variable "license_key" {
  type      = string
  sensitive = true
}

variable "docker_token" {
  type      = string
  sensitive = true
}

variable "environments_management_secret_key" {
  type      = string
  sensitive = true
}

variable "app" {
  type = object({
    version   = string
    log_level = optional(number, 40)
    cpu       = optional(number, 512)
    memory    = optional(number, 1024)
    port      = optional(number, 8000)
  })

  validation {
    condition     = var.app.version != "CHANGE_THIS"
    error_message = "You should adjust the version of the application before creating the resources. Refer to https://ckeditor.com/docs/cs/latest/onpremises/cs-onpremises/changelog.html for the list of currently available versions."
  }
}

variable "redis" {
  type = object({
    node_type = optional(string, "cache.t4g.small")
    instances = optional(number, 1)
  })
  default = {
    node_type = "cache.t4g.small"
    instances = 1
  }
}

variable "mysql" {
  type = object({
    storage     = optional(number, 100)
    iops        = optional(number, 1000)
    db_instance = optional(string, "db.c6gd.medium")
  })
  default = {
    storage     = 100
    iops        = 1000
    db_instance = "db.c6gd.medium"
  }
}
