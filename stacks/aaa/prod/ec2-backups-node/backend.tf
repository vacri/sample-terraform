terraform {
  backend "s3" {
    bucket         = "aaa-terraform"
    key            = "aaa/prod/ec2-backups-node/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}
