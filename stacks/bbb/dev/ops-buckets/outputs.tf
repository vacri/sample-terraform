output "backups_bucket_arn" {
    value = module.s3-ops-buckets["backups_bucket"].s3_bucket_arn
}

output "backups_bucket_name" {
    value = module.s3-ops-buckets["backups_bucket"].s3_bucket_id
}

output "configs_bucket_arn" {
    value = module.s3-ops-buckets["configs_bucket"].s3_bucket_arn
}

output "configs_bucket_name" {
    value = module.s3-ops-buckets["configs_bucket"].s3_bucket_id
}

output "logs_bucket_arn" {
    value = module.s3-ops-buckets["logs_bucket"].s3_bucket_arn
}

output "logs_bucket_name" {
    value = module.s3-ops-buckets["logs_bucket"].s3_bucket_id
}

output "packages_bucket_arn" {
    value = module.s3-ops-buckets["packages_bucket"].s3_bucket_arn
}

output "packages_bucket_name" {
    value = module.s3-ops-buckets["packages_bucket"].s3_bucket_id
}