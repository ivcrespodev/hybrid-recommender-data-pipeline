# ============================================================================
# Description: ETL Module Resource Exposure Output Declarations
# Purpose: Exports critical metadata parameters to the root orchestration layer
# ============================================================================

output "data_lake_bucket_id" {
  description = "The unique identifier (name) of the central Amazon S3 Data Lake bucket storing ML training datasets."
  value       = var.data_lake_bucket
}

output "scripts_bucket_id" {
  description = "The unique identifier (name) of the Amazon S3 bucket hosting deployment scripts and application code."
  value       = var.scripts_bucket
}
