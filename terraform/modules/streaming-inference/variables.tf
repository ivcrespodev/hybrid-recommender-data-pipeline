# ============================================================================
# Description: Streaming Inference Variable Definitions & Input Contract
# Scope: Configures serverless anchors, streaming links, and delivery buckets
# ============================================================================

variable "project" {
  type        = string
  description = "Enterprise deployment namespace prefix used to tag and isolate streaming infrastructure resources."
}

variable "region" {
  type        = string
  description = "Target geographical AWS Region where the streaming architecture nodes will be allocated."
}

variable "kinesis_stream_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) identifying the upstream Kinesis Data Stream capturing real-time transaction logs."
}

variable "inference_api_url" {
  type        = string
  description = "The HTTP/HTTPS connection URL endpoint pointing to the remote serverless inference API hosting the machine learning models."
}

variable "recommendations_bucket" {
  type        = string
  description = "The unique identification name mapping the destination Amazon S3 bucket used as the real-time recommendations data store sink."
}
