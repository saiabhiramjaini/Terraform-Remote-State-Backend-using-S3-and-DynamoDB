terraform {
  backend "s3" {
    bucket         = "terraform-state-file-abc.d6vs"
    key            = "globals/terraform-state-file/terraform.tfstate" 
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt = true
  }
}