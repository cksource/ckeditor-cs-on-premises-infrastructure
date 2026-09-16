module "storage" {
  source = "../../modules/storage"

  bucket_prefix = "cs-on-premises-storage"
  name          = "CS On-Premises Storage"
}
