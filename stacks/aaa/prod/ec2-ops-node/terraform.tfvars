instance_type           = "t4g.micro"
ec2_nametag             = "aaa-prod-ops"
ec2_keypair             = "nat-aaa-prod"
disable_api_termination = true

ec2_root_volume_size = 30

s3_backup_write_perms = false # set to false for ops/non-backup nodes