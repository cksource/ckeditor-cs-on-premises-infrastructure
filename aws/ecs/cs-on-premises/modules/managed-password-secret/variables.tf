variable "name" {
  type        = string
  nullable    = false
  description = "Secrets Manager secret name."
}

variable "description" {
  type        = string
  default     = null
  nullable    = true
  description = "Secrets Manager secret description."
}

