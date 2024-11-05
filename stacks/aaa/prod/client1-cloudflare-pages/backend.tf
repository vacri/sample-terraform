terraform {
  backend "s3" {
    bucket         = "aaa-terraform"
    key            = "aaa/prod/client1-cloudflare-pages/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}
