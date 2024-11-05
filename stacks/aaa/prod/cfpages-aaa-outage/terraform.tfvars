pages_site_config = {
  name = "aaa-outage"
}

pages_build_config = {
  build_command   = "make build"
  destination_dir = "build"
}

pages_source_config = {
  owner             = "YourGithubOrgName"
  repo_name         = "cloudflare-aaa-outage"
  production_branch = "master"
}

# main website domain. the assets bucket domain is set elsewhere
domains = []

s3_create_assets_bucket = false

s3_iam_users = []
