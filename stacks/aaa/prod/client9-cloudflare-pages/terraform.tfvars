pages_site_config = {
  name = "client9"
}

pages_build_config = {
  build_command   = "jekyll build"
  destination_dir = "_site"
}

pages_source_config = {
  owner             = "YourGithubOrgName"
  repo_name         = "client9"
  production_branch = "prod"
}

# main website domain. the assets bucket domain is set elsewhere
domains = [
  "client9.aaa.tools",
  "client9.aaa.com.au"
]


s3_create_assets_bucket = true

s3_iam_users = [
  "johnsmith",
  "janejones"
]


#cost_centre = var.cost_centr
cost_centre = "client9"

