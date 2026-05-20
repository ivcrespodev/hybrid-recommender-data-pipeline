# ==============================================================================
# ETL Module — AWS Glue Catalog, Connection, Crawler & Job
# ==============================================================================

# Glue Data Catalog database for ML training schemas
resource "aws_glue_catalog_database" "ml_database" {
  name        = "${var.project}-analytics-catalog"
  description = "Catalog database storing transformed schemas for ML model training."
}

# JDBC connection to the source MySQL operational database
resource "aws_glue_connection" "rds_connection" {
  name = "${var.project}-relational-store-link"

  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${var.host}:${var.port}/${var.database}"
    USERNAME            = var.username
    PASSWORD            = var.password
  }

  physical_connection_requirements {
    availability_zone      = data.aws_subnet.public_a.availability_zone
    security_group_id_list = [data.aws_security_group.db_sg.id]
    subnet_id              = data.aws_subnet.public_a.id
  }
}

# Crawler that keeps the Glue Data Catalog in sync with new S3 partitions
resource "aws_glue_crawler" "s3_crawler" {
  name          = "${var.project}-training-data-crawler"
  database_name = aws_glue_catalog_database.ml_database.name
  role          = aws_iam_role.glue_role.arn

  s3_target {
    # Must match the output path written by the Glue job (see etl-job.py)
    path = "s3://${var.data_lake_bucket}/ratings_ml_training"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_NEW_FOLDERS_ONLY"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "LOG"
  }
}

# Distributed PySpark ETL job
resource "aws_glue_job" "etl_job" {
  name         = "${var.project}-batch-etl-orchestrator"
  role_arn     = aws_iam_role.glue_role.arn
  glue_version = "4.0"
  connections  = [aws_glue_connection.rds_connection.name]

  command {
    name            = "glueetl"
    script_location = "s3://${var.scripts_bucket}/${var.scripts_key}"
    python_version  = 3
  }

  default_arguments = {
    "--enable-job-insights" = "true"
    "--job-language"        = "python"
    "--glue_connection"     = aws_glue_connection.rds_connection.name
    "--glue_database"       = aws_glue_catalog_database.ml_database.name
    "--target_path"         = "s3://${var.data_lake_bucket}"
  }

  # Maximum runtime in minutes before the job is forcefully terminated
  timeout           = 5
  number_of_workers = 2
  worker_type       = "G.1X"
}
