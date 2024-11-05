output "efs_volume_id" {
  value = aws_efs_file_system.efs_volume.id
}

output "efs_volume_dns_name" {
  value = aws_efs_file_system.efs_volume.dns_name
}

output "efs_volume_name" {
  value = local.efs_volume_name
}

output "efs_mounted_volume_path" {
  value = var.efs_mounted_volume_path
}