variable "name" {
  type        = string
  nullable    = false
  description = "Value of the `Name` tag put on the VPC."
}

variable "az_count" {
  type        = number
  nullable    = false
  description = "Number of availability zones to spread the subnets over."
}

variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  nullable    = false
  description = "CIDR block of the VPC."
}
