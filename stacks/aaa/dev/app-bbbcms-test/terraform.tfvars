use_init_placeholder_image = false # don't switch to false until the ECR repo is populated (ie: github has pushed an image)
cost_centre                = "bbb"

app_name                        = "bbbcms"
github_repo                     = ""                      # used for CI/CD deploy role, nothing else (at the moment)
create_ecr_repo_and_github_role = false                   # only do this for a single env for this app (eg: prod env, but not test/stag)
app_env                         = "test"                  # if you want to change the env from the terraform stack env (uat/qa/test/stag/etc will all be in terraform 'dev')
host_headers                    = ["test-cms.bbb.tools"] # must be unique for that env/loadbalancer. LB must also have https cert that covers the host (manually installed)
alb_https_listener_priority     = 620                     #must be unique for that loadbalancer
create_s3_assets_bucket         = true

container_image  = "public.ecr.aws/aaaops/directus-soe" # should be the full docker image URI, minus the label
container_label  = "9.26"                               # should be the 'env' for the item (prod/dev/test/stag/qa/whatever)
container_port   = 8080
container_cpu    = 512  # see variables.tf comments for allowable cpu/mem combinations
container_memory = 1024 # use numbers rather than string for this entry - see variables.tf

container_count_max     = 4
container_count_min     = 1
container_count_desired = 1

health_check_path                = "/server/health" # directus's health check path
health_check_unhealthy_threshold = "6"              # seems to be slow to start up, at least on tiny containers
