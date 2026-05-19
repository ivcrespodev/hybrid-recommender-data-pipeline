# ============================================================================
# Description: AWS Glue Catalog & ETL Data Pipeline Configurations
# Target Layer: Batch Processing / Historical Data Lakes
# Data Governance: Analytics Data Catalog Database
# ============================================================================

resource "aws_glue_catalog_database" "ml_database" {
  name        = "${var.project}-analytics-catalog"
  description = "Central analytical database catalog storing transformed schemas for machine learning model training pipelines."
}

# 1. Establish secure network link to the Operational MySQL Database Instance
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

# 2. Schema Discovery Crawler mapping vectorized training files to the Glue Data Catalog
resource "aws_glue_crawler" "s3_crawler" {
  name          = "${var.project}-training-data-crawler"
  database_name = aws_glue_catalog_database.ml_database.name
  role          = aws_iam_role.glue_role.arn

  s3_target {
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

# 3. Distributed PySpark ETL Workload Orchestrator
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

  timeout = 5

  # Computing cluster optimization metrics for parallel Spark executions
  number_of_workers = 2
  worker_type       = "G.1X"
}