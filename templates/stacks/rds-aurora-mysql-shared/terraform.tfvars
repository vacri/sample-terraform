# aurora-mysql versioning described here: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Updates.Versions.html
aurora_config = {
  engine          = "aurora-mysql"
  version         = "8.0.mysql_aurora.3.02.0"
  name_suffix     = "mysql-shared"
  min_capacity    = "0.5"
  max_capacity    = "4"
  master_username = "root"
}
