# ==============================================================================
# Vector DB Module — Output Declarations
# ==============================================================================

output "vector_db_master_username" {
  description = "Master username of the PostgreSQL vector database."
  value       = var.master_username
  sensitive   = true
}

output "vector_db_master_password" {
  description = "Auto-generated master password of the PostgreSQL vector database."
  value       = random_password.master_password.result
  sensitive   = true
}

output "vector_db_host" {
  description = "Endpoint address of the PostgreSQL vector database instance."
  value       = aws_db_instance.master_db.address
}

output "vector_db_port" {
  description = "Port of the PostgreSQL vector database instance."
  value       = aws_db_instance.master_db.port
}
