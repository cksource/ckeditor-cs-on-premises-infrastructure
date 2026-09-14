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

# Stringified JSON object passed to the container as the `PROVIDERS`
# environment variable. At least one LLM provider has to be configured for the
# service to start.
variable "providers_config" {
  type      = string
  sensitive = true
}

# Stringified JSON array passed to the container as the `MODELS` environment
# variable. Leave it empty to use the default model list of every configured
# provider.
variable "models_config" {
  type     = string
  nullable = false
  default  = ""
}

variable "app" {
  type = object({
    version   = string
    log_level = optional(number, 40)
    cpu       = optional(number, 1024)
    memory    = optional(number, 2048)
    port      = optional(number, 8000)
    # The documentation recommends running at least 3 instances for high
    # availability. The default is 2 to keep the cost of this example lower.
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
