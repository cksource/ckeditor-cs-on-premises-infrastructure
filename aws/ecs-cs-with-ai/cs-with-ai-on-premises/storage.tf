module "storage" {
  source = "../../modules/storage"

  bucket_prefix = "cs-with-ai-on-premises-storage"
  name          = "CS with AI On-Premises Storage"
}
