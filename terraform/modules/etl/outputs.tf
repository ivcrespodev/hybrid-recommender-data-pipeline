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
