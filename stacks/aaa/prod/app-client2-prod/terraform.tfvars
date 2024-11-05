use_init_placeholder_image = false # don't switch to false until the ECR repo is populated (ie: github has pushed an image)

app_name    = "client2"
app_env     = "prod"       # if you want to change the env from the terraform stack env (uat/qa/test/stag/etc will all be in terraform 'dev')
github_repo = "client2-cloud" # used for CI/CD deploy role

create_ecr_repo         = true
ecr_foreign_account_ids = []
ecr_foreign_repo_arn    = ""

host_headers                = ["prod-client2.aaa.tools", "client2.aaa.com.au"] # must be unique for that env/loadbalancer. LB must also have https cert that covers the host (manually installed)
alb_https_listener_priority = 430                                            #must be unique for that loadbalancer
create_s3_assets_bucket     = true
s3_backup_tag               = true

container_image  = "2345678901234.dkr.ecr.ap-southeast-2.amazonaws.com/client2" # should be the full docker image URI, minus the label
container_label  = "prod"                                                   # should be the 'env' for the item (prod/dev/test/stag/qa/whatever)
container_port   = 8080
container_cpu    = 512  # see variables.tf comments for allowable cpu/mem combinations
container_memory = 1024 # use numbers rather than string for this entry - see variables.tf

container_count_max     = 4
container_count_min     = 1
container_count_desired = 1

efs_mounted_volume_paths = ["/var/www/html/sites/default/files"] # NOT MORE THAN ONE PATH!
