# ============================================================================
# Description: Vector Database Module Resource Exposure Output Declarations
# Purpose: Exports critical connection parameters to the root orchestration layer
# ============================================================================

output "vector_db_master_username" {
  description = "The master administrative database user principal account name authorized to manage schemas."
  value       = var.master_username
  sensitive   = true
}

output "vector_db_master_password" {
  description = "The cryptographically generated secret master administrative database password credential."
  value       = random_id.master_password.id
  sensitive   = true
}

output "vector_db_host" {
  description = "The connection network address endpoint string pointing to the active provisioned database instance."
  value       = aws_db_instance.master_db.address
}

output "vector_db_port" {
  description = "The target network communication port designated to route traffic into the relational vector store."
  value       = aws_db_instance.master_db.port
}
