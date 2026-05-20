# ==============================================================================
# Streaming Inference Module — Input Variable Declarations
# ==============================================================================

variable "project" {
  type        = string
  description = "Prefix applied to all resource names and tags."
}

variable "region" {
  type        = string
  description = "AWS region where streaming resources are provisioned."
}

variable "kinesis_stream_arn" {
  type        = string
  description = "ARN of the upstream Kinesis Data Stream supplying real-time events."
}

variable "inference_api_url" {
  type        = string
  description = "URL of the inference Lambda function that serves recommendation vectors."
}

variable "recommendations_bucket" {
  type        = string
  description = "Name of the S3 bucket where Firehose delivers recommendation payloads."
}
