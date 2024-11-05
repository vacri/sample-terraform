engine         = "mysql"
engine_version = "8.0.32"
#major_engine_version = "8"
port              = 3306
instance_class    = "db.t3.small"
allocated_storage = 20

# not available for mysql t3/t4.small or smaller
performance_insights_enabled = false

apply_immediately = true