terraform {
  backend "s3" {
    bucket         = "aaa-terraform"
    key            = "aaa/dev/app-php-sandbox/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}
