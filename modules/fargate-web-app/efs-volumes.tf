
data "aws_security_groups" "ec2_backups_node" {
  filter {
    name   = "group-name"
    values = ["ec2-backups-nodes*"]
  }
}


module "fargate_efs_submodule" {

  for_each = toset(var.efs_mounted_volume_paths)

  source  = "../fargate-web-app-efs-submodule"
  app     = var.app
  ou      = var.ou
  env     = var.env
  app_env = var.app_env

  efs_mounted_volume_path = trimsuffix(each.value, "/")
  efs_backup_tag          = var.efs_backup_tag

  vpc_id              = var.vpc_id
  ecs_cluster_subnets = var.ecs_cluster_subnets

  target_security_group_ids = concat(
    [aws_security_group.ecs_service.id],
    data.aws_security_groups.ec2_backups_node.ids,
    var.efs_extra_writemount_security_groups
  )

}