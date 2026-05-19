# ============================================================================
# Description: Streaming Inference Module Resource Output Declarations
# Purpose: Exports runtime target bucket metadata to the root orchestration layer
# ============================================================================

output "recommendations_bucket_id" {
  description = "The unique identifier (name) of the target Amazon S3 bucket where final computed real-time user recommendations are delivered by Kinesis Firehose."
  value       = var.recommendations_bucket
}
