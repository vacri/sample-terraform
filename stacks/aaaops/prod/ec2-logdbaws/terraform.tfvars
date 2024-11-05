instance_name           = "logdbaws"
instance_type           = "r5.large"
disable_api_termination = true
ec2_keypair             = "jumphost-shared-services" #only matters for initial ansible bootstrapping

ami_filter_strings = [ "debian-12-amd64-*" ]

ec2_root_volume_size = 100