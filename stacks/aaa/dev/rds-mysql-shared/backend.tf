terraform {
  backend "s3" {
    bucket         = "aaa-terraform"
    key            = "aaa/dev/rds-mysql-shared/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}
