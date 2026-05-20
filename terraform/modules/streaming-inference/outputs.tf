# ==============================================================================
# Streaming Inference Module — Output Declarations
# ==============================================================================

output "recommendations_bucket_id" {
  description = "Name of the S3 bucket receiving Firehose recommendation payloads."
  value       = var.recommendations_bucket
}
