terraform {
  backend "s3" {
    bucket         = "aaa-terraform"
    key            = "bbb/dev/ops-buckets/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}
