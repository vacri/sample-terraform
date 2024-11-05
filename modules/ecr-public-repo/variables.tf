variable "ecr_repo_name" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "github_org" {
  type    = string
  default = "YourGithubOrgNameHere"
}

variable "github_repo" {
  type    = string
  default = ""
}