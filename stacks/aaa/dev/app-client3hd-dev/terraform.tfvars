use_init_placeholder_image = false # don't switch to false until the ECR repo is populated (ie: github has pushed an image)

app_name    = "client3hd"
app_env     = "dev"         # if you want to change the env from the terraform stack env (uat/qa/test/stag/etc will all be in terraform 'dev')
github_repo = "client3_hd" # used for CI/CD deploy role

create_ecr_repo = true # usually each env will get its own repo. You may not want a repo if you're using someone else's image
#ecr_foreign_account_ids = []   # these 'foreign' vars are for using cross-account ECR repos, which we've decided against for the moment
#ecr_foreign_repo_arn    = ""   # see notes in variables.tf

host_headers                = ["dev-client3-hd.aaa.tools"] # must be unique for that env/loadbalancer. LB must also have https cert that covers the host (manually installed)
alb_https_listener_priority = 226                    #must be unique for that loadbalancer
create_s3_assets_bucket     = false
s3_bucket_suffix            = "" # add one (start with a hyphen) if your s3 bucket name is already taken

efs_mounted_volume_paths = [ "/var/www/html/web/sites/default/files" ] # no trailing slash, plox (cleaner namespace)
efs_backup_tag = true

s3_backup_tag = true

container_image  = "123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/client3hd" # should be the full docker image URI, minus the label - should match the ecr repo indicated above
container_label  = "dev"                                                               # should be the 'env' for the item (prod/dev/test/stag/qa/whatever)
container_port   = 8080
container_cpu    = 256 # see variables.tf comments for allowable cpu/mem combinations
container_memory = 512 # use numbers rather than string for this entry - see variables.tf

container_count_max     = 2
container_count_min     = 1
container_count_desired = 1

health_check_path  = "/"
health_check_codes = "200-400"  # ELB check has no hostname. Drupal gives a 400 if not in 'trusted_hosts' list