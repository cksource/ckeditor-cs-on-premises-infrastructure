module "network" {
  source = "../../modules/network"

  name     = "CS On-Premises"
  az_count = var.az_count
}
