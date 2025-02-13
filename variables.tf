variable "s3_bucket_name" {
  description = "Name of our S3 bucket to store state file"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of our dynamodb table to prevent locking of state file"
  type        = string
}