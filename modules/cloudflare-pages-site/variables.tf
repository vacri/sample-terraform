
variable "cloudflare_account_id" {
  type    = string
  default = "placeholder"
}

variable "domains" {
  type    = list(string)
  default = []
}
variable "pages_site_config" {
  type = map(any)
  default = {
    name = "placeholder"
    #production_branch = "main"
  }
}

variable "pages_build_config" {
  type = map(any)
  default = {
    build_command   = "make build"
    destination_dir = "build"
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


# separate from below map as can't mix element types (string, list) in same map
variable "pages_source_config" {
  type = map(any)
  default = {
    owner             = "YourGithubOrgName"
    repo_name         = "placeholder"
    production_branch = "prod"
  }
}

# separate from above map as can't mix element types (string, list) in same map
variable "pages_source_preview_config" {
  type = map(any)
  default = {
    preview_branch_includes = ["dev", "stag"]
    preview_branch_excludes = ["main", "prod"]
  }
}

variable "s3_website_config" {
  type = map(any)
  default = {
    index_document = "index.html"
    error_document = "error.html"
  }
}

variable "s3_create_assets_bucket" {
  type    = bool
  default = false
}

variable "s3_iam_users" {
  type    = list(string)
  default = []
}

# must match the domain suffix below
variable "cloudflare_zone_id" {
  type    = string
  default = "b84c541d6d98b8d4b4980cafc9bba8d6" # aaa.tools
}

variable "assets_site_domain" {
  type    = string
  default = "aaa.tools"
}

variable "assets_site_hostname_suffix" {
  type    = string
  default = "cdn"
}

# variable "github_repo_name" {
#   type    = string
#   default = ""
# }

# variable "gitignore_template" {
#   type    = string
#   default = "Node"
# }