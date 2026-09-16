variable "bucket_prefix" {
  type        = string
  nullable    = false
  description = "Prefix of the bucket name. A random suffix is appended to keep it globally unique."
}

variable "name" {
  type        = string
  nullable    = false
  description = "Value of the `Name` tag put on the bucket."
}
