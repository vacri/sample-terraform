variable "aurora_config" {
  type = map(string)
  default = {
    engine          = "aurora_postgresql"
    version         = "13.10"
    name_suffix     = "psql-shared"
    min_capacity    = "0.5"
    max_capacity    = "4"
    master_username = "postgres"
  }
}