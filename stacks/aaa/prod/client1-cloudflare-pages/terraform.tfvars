pages_site_config = {
  name = "client1"
}

pages_build_config = {
  build_command   = "npm run build"
  destination_dir = "build"
}

pages_source_config = {
  owner             = "YourGithubOrgName"
  repo_name         = "client1"
  production_branch = "prod"
}

pages_deployment_preview_configs = {
  environment_variables = {
    NODE_VERSION = 18
  }
}
pages_deployment_production_configs = {
  environment_variables = {
    NODE_VERSION = 18
  }
}



# main website domain. the assets bucket domain is set elsewhere
domains = [
  "client1.aaa.tools",
  "client1.aaa.com.au"
]


s3_create_assets_bucket = true

s3_iam_users = [
  "johnqpublic"
]

cost_centre = "client1"

