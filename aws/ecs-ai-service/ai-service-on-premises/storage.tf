module "storage" {
  source = "../../modules/storage"

  bucket_prefix = "ai-service-on-premises-storage"
  name          = "CKEditor AI Service On-Premises Storage"
}
