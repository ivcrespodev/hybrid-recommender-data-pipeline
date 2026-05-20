# ==============================================================================
# Root Output Declarations
# ==============================================================================

# --- ETL / Batch Layer ---

output "data_lake_bucket_id" {
  description = "Name of the S3 Data Lake bucket storing ML training datasets."
  value       = module.etl.data_lake_bucket_id
}

output "scripts_bucket_id" {
  description = "Name of the S3 bucket hosting the Glue ETL script."
  value       = module.etl.scripts_bucket_id
}

# --- Vector Database ---

output "vector_db_host" {
  description = "Connection endpoint of the PostgreSQL vector database instance."
  value       = module.vector_db.vector_db_host
}

output "vector_db_port" {
  description = "Port of the PostgreSQL vector database instance."
  value       = module.vector_db.vector_db_port
}

output "vector_db_master_username" {
  description = "Master username for the PostgreSQL vector database."
  value       = module.vector_db.vector_db_master_username
  sensitive   = true
}

output "vector_db_master_password" {
  description = "Auto-generated master password for the PostgreSQL vector database."
  value       = module.vector_db.vector_db_master_password
  sensitive   = true
}

# --- Streaming / Hot Path ---

output "recommendations_bucket_id" {
  description = "Name of the S3 bucket receiving Firehose recommendation payloads."
  value       = module.streaming_inference.recommendations_bucket_id
}
