use_init_placeholder_image = false # don't switch to false until the ECR repo is populated (ie: github has pushed an image)

app_name                    = "web-sandbox"
app_env                     = "dev"
github_repo                 = "web-sandbox"             # used for CI/CD deploy role
create_ecr_repo             = true                      # usually each env will get its own repo. You may not want a repo if you're using someone else's image
host_headers                = ["web-sandbox.aaa.tools"] # must be unique for that env/loadbalancer. LB must also have https cert that covers the host (manually installed)
alb_https_listener_priority = 810                       #must be unique for that loadbalancer
create_s3_assets_bucket     = true
s3_backup_tag               = false

container_image  = "123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/web-sandbox" # should be the full docker image URI, minus the label
container_label  = "dev"                                                           # should be the 'env' for the item (prod/dev/test/stag/qa/whatever)
container_port   = 8080
container_cpu    = 256 # see variables.tf comments for allowable cpu/mem combinations
container_memory = 512 # use numbers rather than string for this entry - see variables.tf

container_count_max     = 4
container_count_min     = 1
container_count_desired = 1

efs_mounted_volume_paths = ["/mnt", "/tmp/efstest"]
