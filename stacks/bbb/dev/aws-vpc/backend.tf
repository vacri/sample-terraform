terraform {
  backend "s3" {
    bucket         = "aaa-terraform"
    key            = "bbb/dev/aws-vpc/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}
