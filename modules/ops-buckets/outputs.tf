output "backups_bucket" {
  value = module.s3_bucket_configs["backups"]
}

output "configs_bucket" {
  value = module.s3_bucket_configs["configs"]
}

output "logs_bucket" {
  value = module.s3_bucket_configs["logs"]
}

output "packages_bucket" {
  value = module.s3_bucket_configs["packages"]
}