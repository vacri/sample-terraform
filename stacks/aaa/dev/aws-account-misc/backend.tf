terraform {
  backend "s3" {
    bucket         = "aaa-terraform"
    key            = "aaa/dev/aws-account-misc/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}
