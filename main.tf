module "backend" {
  source = "./modules/backend"

  s3_bucket_name = var.s3_bucket_name
  dynamodb_table_name = var.dynamodb_table_name
}