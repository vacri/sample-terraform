use_init_placeholder_image = false # don't switch to false until the ECR repo is populated (ie: github has pushed an image)

app_name    = "client5"
app_env     = "dev"     # if you want to change the env from the terraform stack env (uat/qa/test/stag/etc will all be in terraform 'dev')
github_repo = "client5" # used for CI/CD deploy role

create_ecr_repo         = true
ecr_foreign_account_ids = [] # put the ids of other AWS accounts that need to pull/push from this repo
ecr_foreign_repo_arn    = "" # if not creating our own repo in this stack, put the arn of the repo we'll be push/pulling to

host_headers                = ["dev-client5.aaa.tools"] # must be unique for that env/loadbalancer. LB must also have https cert that covers the host (manually installed)
alb_https_listener_priority = 550                       #must be unique for that loadbalancer
create_s3_assets_bucket     = true
s3_bucket_suffix            = "-aaa"
s3_backup_tag               = false

s3_enable_current_version_transition = true

container_image  = "123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/client5" # should be the full docker image URI, minus the label - should match the ecr repo indicated above
container_label  = "dev"                                                       # should be the 'env' for the item (prod/dev/test/stag/qa/whatever)
container_port   = 8080
container_cpu    = 1024 # see variables.tf comments for allowable cpu/mem combinations
container_memory = 2048 # use numbers rather than string for this entry - see variables.tf

container_count_max     = 2
container_count_min     = 1
container_count_desired = 1

health_check_path = "/help/"