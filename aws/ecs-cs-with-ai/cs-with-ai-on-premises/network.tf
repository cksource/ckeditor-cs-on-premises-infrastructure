module "network" {
  source = "../../modules/network"

  name     = "CS with AI On-Premises"
  az_count = var.az_count
}
