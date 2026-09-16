variable "az_count" {
  type    = number
  default = 3
}

variable "aws_region" {
  type = string
}

variable "cs_license_key" {
  type      = string
  sensitive = true
}

variable "ai_license_key" {
  type      = string
  sensitive = true
}

variable "cs_docker_token" {
  type      = string
  sensitive = true
}

variable "ai_docker_token" {
  type      = string
  sensitive = true
}

variable "environments_management_secret_key" {
  type      = string
  sensitive = true
}

variable "providers_config" {
  type      = string
  sensitive = true
}

variable "models_config" {
  type     = string
  nullable = false
  default  = ""
}

variable "cs_app" {
  type = object({
    version   = string
    log_level = optional(number, 40)
    cpu       = optional(number, 512)
    memory    = optional(number, 1024)
    port      = optional(number, 8000)
    instances = optional(number, 2)
  })
}

variable "ai_app" {
  type = object({
    version   = string
    log_level = optional(number, 40)
    cpu       = optional(number, 1024)
    memory    = optional(number, 2048)
    port      = optional(number, 8000)
    instances = optional(number, 2)
  })
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
