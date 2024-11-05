terraform {
  backend "s3" {
    bucket         = "aaa-terraform"
    key            = "aaaops/prod/ec2-jumphost/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}
