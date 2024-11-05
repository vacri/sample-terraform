pages_site_config = {
  name = ""
}

pages_build_config = {
  build_command   = "make build"
  destination_dir = "build"
}

pages_source_config = {
  owner             = "CloudflareAccountNameGoesHere"
  repo_name         = "CHANGEME"
  production_branch = "prod"
}

# main website domain. the assets bucket domain is set elsewhere
domains = []

s3_create_assets_bucket = false

s3_iam_users = []
