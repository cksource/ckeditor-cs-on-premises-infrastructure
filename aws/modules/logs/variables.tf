variable "name" {
  type        = string
  nullable    = false
  description = "CloudWatch log group name."
}

variable "task_execution_role_id" {
  type        = string
  nullable    = false
  description = "ID of the ECS task execution role the log-writing policy is attached to."
}

variable "retention_in_days" {
  type        = number
  default     = 30
  nullable    = false
  description = "How long log events are kept."
}
