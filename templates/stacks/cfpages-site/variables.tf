variable "cloudflare_api_token" {
  type     = string
  nullable = false
}

variable "pages_site_config" {
  type = map(string)
  default = {
    name = ""
  }
}

variable "pages_build_config" {
  type = map(string)
  default = {
    build_command   = "make build"
    destination_dir = "build/"
  }
}

variable "pages_deployment_preview_configs" {
  type = map(any)
  default = {
    environment_variables = {}
  }
}
variable "pages_deployment_production_configs" {
  type = map(any)
  default = {
    environment_variables = {}
  }
}

variable "pages_source_config" {
  type = map(string)
  default = {
    owner             = "CloudflareAccountNameGoesHere"
    repo_name         = null
    production_branch = "prod"
  }
}

# main website domain. the assets bucket domain is set elsewhere
variable "domains" {
  type    = list(string)
  default = ["example.com"]
}

variable "s3_iam_users" {
  type    = list(string)
  default = []
}

variable "s3_create_assets_bucket" {
  type    = bool
  default = false
}
