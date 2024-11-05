instance_type           = "t4g.micro"
ec2_nametag             = "aaa-dev-backups"
ec2_keypair             = "nat-aaa-dev"
disable_api_termination = true

ec2_root_volume_size = 20

s3_backup_write_perms = true  # set to false for ops/non-backup nodes

backups_secrets_access = true  # set to false for ops/non-backup nodes