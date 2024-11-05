# this submodule is intended to be called by the fargate-web-app module.
# this is a separate module so that we can turn EFS on and off with a single call
# rather than having to individually configure a toggle for a variety of conflicting resources

locals {
  #efs_subnets = var.efs_mounted_volume_paths == [] ? [] : var.ecs_cluster_subnets
  efs_subnets     = var.ecs_cluster_subnets
  efs_volume_name = "${var.app}-${var.app_env}-efs${replace(var.efs_mounted_volume_path, "/", "-")}"
}

##
## EFS volume (optional)
##
# https://stackoverflow.com/questions/71309915/providing-access-to-efs-from-ecs-task
# https://medium.com/@ilia.lazebnik/attaching-an-efs-file-system-to-an-ecs-task-7bd15b76a6ef

# This EFS code is hot garbage. It's been a real mess dealing with trying to iterate over a list, plus
# combine this with the json Task Definition above. But it's required to support Client2.
# The alternative is to have a separate json config altogether and switch between them
# based on a conditional, rather than trying to dynamically adjust stuff. But that sucks even more

resource "aws_efs_file_system" "efs_volume" {

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  encrypted = true

  tags = {
    Name   = local.efs_volume_name
    backup = var.efs_backup_tag
  }

  ## as we can't restore the file with transition_to_primary, am disabling the transition_to_ia as well
  # lifecycle_policy {
  #   transition_to_ia = "AFTER_30_DAYS"
  #   # below line requires terraform AWS provider v5+... except even on 5.5, I get malformed request
  #   transition_to_primary_storage_class = "AFTER_1_ACCESS"
  # }
  ## apparently works if you split up into single directives
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }


  #   lifecycle {
  #     prevent_destroy = true
  #   }
}

# this is an entire resource dedicated to a single boolean value...
resource "aws_efs_backup_policy" "efs_backup" {
  file_system_id = aws_efs_file_system.efs_volume.id
  backup_policy {
    status = "ENABLED"
  }
}

# This resource is needed for ECS to mount the volume, even though it's not specified in the ECS Task Definition.
#
# This resource also forbids us from having multiple paths/mounted volumes in the list - we would need to use 
# "setproduct()" as we have two lists ('subnets' + 'multiple volumes'), and the volume list is from another resource
# Terraform will not let us use a list of resources that hasn't been generated yet in setproduct().
# As a result, we have no way of programmatically identifying which volume to use by generated id -
# so we have to hardcode it to a single one ([0])
# TODO: fix this by replacing toset() with maps instead of sets, and whatever is needed
# instead of setproduct() to combine "subnets" and "efs ids"
# sorry about the mess.
resource "aws_efs_mount_target" "mount" {
  #for_each = toset(local.efs_subnets)
  #file_system_id = aws_efs_file_system.efs_volume[0].id
  for_each        = toset(local.efs_subnets)
  file_system_id  = aws_efs_file_system.efs_volume.id
  security_groups = [aws_security_group.efs_volume.id]
  subnet_id       = each.value

  ## I kinda got the combination of the two lists working, but it still fails on more than one item
  ## giving an error about the first list in the setproduct
  ## have left this code here for reference re: the setproduct construct.
  ## WARNING If you re-enable this code, you ALSO must:
  ## * in the ecs task definition, fix the "mountPoints" to handle more than one EFS volume
  ##    * both the id and the friendly name
  ##    * see comments there for the difficulties around that
  ## * in the ecs task definition dynamic 'volumes' block, change the friendly 'name'
  ##    * should be uniqueified with the path name, currently it doesn't vary
  ## * mv existing resources in existing stacks to the new names given by this block
  # for_each = {
  #   for mount in setproduct(toset([ for v in aws_efs_file_system.efs_volume: v.id ]), local.efs_subnets) : "${mount[0]}-${mount[1]}" => {
  #     volume = mount[0]
  #     subnet = mount[1]
  #   }
  # }
  # file_system_id = each.value.volume
  # subnet_id = each.value.subnet
  # security_groups = [aws_security_group.efs_volume.id]
}


resource "aws_security_group" "efs_volume" {
  #count = var.efs_mounted_volume_paths != [] ? 1 : 0

  name   = "${var.app}-${var.app_env}-efs${replace(var.efs_mounted_volume_path, "/", "-")}-sg"
  vpc_id = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    security_groups = var.target_security_group_ids
    #cidr_blocks      = ["0.0.0.0/0"] # TODO: import vpc data and add private subnets here
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
