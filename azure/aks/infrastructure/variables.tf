variable "ssh_public_key" {
  description = "Path to SSH public key passed as authorized key in kubernetes node group"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "name_prefix" {
  description = "Prefix for all resources names"
  type        = string
  default     = "cksourcecs"
}

variable "resource_group_name" {
  description = "Azure resource group name to use for deployment"
  type        = string
  default     = "CKSourceResourceGroup"
}

variable "resource_group_location" {
  description = "Azure resource group location to use for deployment"
  type        = string
  default     = "germanywestcentral"
}

variable "mysql_user" {
  description = "Username for mysql admin user"
  type        = string
  default     = "cs"
}

variable "mysql_password" {
  description = "Overwrites default random password for mysql admin user"
  type        = string
  default     = ""
}

variable "node_pool_vm_size" {
  description = "Kubernetes default node pool VM size"
  type        = string
  default     = "Standard_D2_v2"
}

variable "mysql_flexible_server_sku_name" {
  description = "SKU name of database system size for Azure MySQL Flexible Server"
  type        = string
  default     = "B_Standard_B2s"
}

variable "redis_cache_capacity" {
  description = "Capacity of Azure Redis Cache cluster"
  type        = number
  default     = 2
}

variable "redis_cache_family" {
  description = "Family of Azure Redis Cache cluster instances"
  type        = string
  default     = "C"
}

variable "redis_cache_sku_name" {
  description = "SKU of Azure Redis Cache cluster instances"
  type        = string
  default     = "Standard"
}

variable "aks_node_pool_min_count" {
  description = "Minimal number of nodes in Azure AKS cluster"
  type        = string
  default     = 3
}

variable "aks_node_pool_max_count" {
  description = "Maximum number of nodes in Azure AKS cluster"
  type        = string
  default     = 5
}
