# ============================================================================
# Description: Global Root Infrastructure Output Declarations
# Purpose: Consolidates and exposes core deployment metadata across layers
# Scope: Public network interfaces, storage targets, and secure credentials
# ============================================================================

# ----------------------------------------------------------------------------
# Cold Path Layer Outputs (Batch / Data Lake)
# ----------------------------------------------------------------------------
output "data_lake_bucket_id" {
  description = "The unique identifier (name) of the central Amazon S3 Data Lake storing processed training historical arrays."
  value       = module.etl.data_lake_bucket_id
}

output "scripts_bucket_id" {
  description = "The unique identifier (name) of the Amazon S3 bucket housing the orchestration engine scripts."
  value       = module.etl.scripts_bucket_id
}

# ----------------------------------------------------------------------------
# Storage Analytical Core Outputs (Vector Database Store)
# ----------------------------------------------------------------------------
output "vector_db_master_username" {
  description = "The administrative user principal account name authorized to manage database schemas."
  value       = module.vector_db.vector_db_master_username
  sensitive   = true
}

output "vector_db_master_password" {
  description = "The high-entropy secret password credential protecting the administrative database user account."
  value       = module.vector_db.vector_db_master_password
  sensitive   = true
}

output "vector_db_host" {
  description = "The network connection string endpoint address of the provisioned PostgreSQL vector database instance."
  value       = module.vector_db.vector_db_host
}

output "vector_db_port" {
  description = "The target network communication port designated to route queries into the relational database engine."
  value       = module.vector_db.vector_db_port
}

# ----------------------------------------------------------------------------
# Hot Path Layer Outputs (Real-Time Inference / Streaming)
# ----------------------------------------------------------------------------
output "recommendations_bucket_id" {
  description = "The unique identifier (name) of the target Amazon S3 bucket receiving computed inline stream recommendations."
  value       = module.streaming_inference.recommendations_bucket_id
}
