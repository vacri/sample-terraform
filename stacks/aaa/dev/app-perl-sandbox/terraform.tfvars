use_init_placeholder_image = false # don't switch to false until the ECR repo is populated (ie: github has pushed an image)

app_name                        = "perl-sandbox"
github_repo                     = "perl-sandbox"
create_ecr_repo_and_github_role = true # only do this for a single stack for this app (eg: prod env, but not test/stag)
#app_env = "qa"   # if you want to change the env from the terraform stack env (uat/qa/test/stag/etc will all be in terraform 'dev')
host_headers                = ["perl-sandbox.aaa.tools"] # must be unique for that env/loadbalancer
alb_https_listener_priority = 700
create_s3_assets_bucket     = true

container_image = "123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/perl-sandbox" # should be the full docker image URI, minus the label
container_label = "dev"                                                            # should be the 'env' for the item (dev/test/stag/qa/whatever)
container_port  = 8080

container_count_max     = 4
container_count_min     = 1
container_count_desired = 1