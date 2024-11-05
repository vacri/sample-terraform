use_init_placeholder_image = false # don't switch to false until the ECR repo is populated (ie: github has pushed an image)

app_name    = "client4"
app_env     = "prod"       # if you want to change the env from the terraform stack env (uat/qa/test/stag/etc will all be in terraform 'dev')
github_repo = "client4" # used for CI/CD deploy role

create_ecr_repo = true # usually each env will get its own repo. You may not want a repo if you're using someone else's image


host_headers                = ["prod-client4.aaa.tools", "www.client4.com"] # must be unique for that env/loadbalancer. LB must also have https cert that covers the host (manually installed)
alb_https_listener_priority = 482                           #must be unique for that loadbalancer
create_s3_assets_bucket     = false
s3_bucket_suffix            = "" # add one (start with a hyphen) if your s3 bucket name is already taken
s3_backup_tag               = true

efs_mounted_volume_paths = ["/var/www/html/wp-content/uploads/"]

container_image  = "2345678901234.dkr.ecr.ap-southeast-2.amazonaws.com/client4" # should be the full docker image URI, minus the label - should match the ecr repo indicated above
container_label  = "prod"                                                         # should be the 'env' for the item (prod/dev/test/stag/qa/whatever)
container_port   = 8080
container_cpu    = 512  # see variables.tf comments for allowable cpu/mem combinations
container_memory = 1024 # use numbers rather than string for this entry - see variables.tf

container_count_max     = 2
container_count_min     = 1
container_count_desired = 1

health_check_path  = "/"
health_check_codes = "200-399"