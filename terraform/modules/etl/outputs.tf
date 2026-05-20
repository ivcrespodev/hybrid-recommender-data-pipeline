# ==============================================================================
# ETL Module — Output Declarations
# ==============================================================================

output "data_lake_bucket_id" {
  description = "Name of the S3 Data Lake bucket storing ML training datasets."
  value       = var.data_lake_bucket
}

output "scripts_bucket_id" {
  description = "Name of the S3 bucket hosting the Glue ETL script."
  value       = var.scripts_bucket
}

output "glue_connection_name" {
  description = "Name of the Glue JDBC connection to the source MySQL database."
  value       = aws_glue_connection.rds_connection.name
}
