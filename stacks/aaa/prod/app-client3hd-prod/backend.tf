terraform {
  backend "s3" {
    bucket         = "aaa-terraform"
    key            = "aaa/prod/app-client3hd-prod/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}