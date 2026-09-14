module "network" {
  source = "../../modules/network"

  name     = "CKEditor AI Service On-Premises"
  az_count = var.az_count
}
