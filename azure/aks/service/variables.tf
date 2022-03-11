variable "docker_host" {
  description = "Overwrite CKSource Cloud Services default container registry server"
  type        = string
  default     = "docker.cke-cs.com"
}

variable "docker_username" {
  description = "Overwrite CKSource Cloud Services default container registry username"
  type        = string
  default     = "cs"
}

variable "docker_token" {
  description = "The `docker_token` can be found in CKEditor Ecosystem Dashboard in your CKEditor Collaboration Server On-Premises subscription page in the *Download token* section. If you do not see any tokens, you can create them with the *Create new token* button."
  type        = string
}

variable "kube_config" {
  description = "Kubeconfig object exported from the infrastructure module"
  type = list(object({
    client_certificate : string,
    client_key : string,
    cluster_ca_certificate : string,
    host : string,
    password : string,
    username : string
  }))
}

variable "environments_management_secret_key" {
  description = "Dashboard API secret"
  type        = string
}

variable "license_key" {
  description = "License key for CKEditor Collaboration Server On-Premises"
  type        = string
}

variable "mysql_host" {
  description = "Host of mysql instance"
  type        = string
}

variable "mysql_user" {
  description = "Username for mysql connection"
  type        = string
  default     = "ckeditorcs"
}

variable "mysql_password" {
  description = "Password for mysql connection"
  type        = string
  default     = ""
}

variable "mysql_database" {
  description = "Name of the MySQL database"
  type        = string
  default     = "cs-on-premises"
}

variable "redis_host" {
  description = "Host of redis instance"
  type        = string
}

variable "redis_password" {
  description = "Password to redis instance"
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Name of the Azure storage account"
  type        = string
}

variable "storage_account_key" {
  description = "Access key to Azure storage account"
  type        = string
}

variable "storage_container" {
  description = "Name of the Azure storage container"
  type        = string
}
