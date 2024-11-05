terraform {
  backend "s3" {
    bucket         = "aaa-terraform"
    key            = "aaa/dev/fargate-cluster-shared/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}
