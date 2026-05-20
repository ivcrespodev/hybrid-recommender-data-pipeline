# ==============================================================================
# Root Input Variable Declarations
# ==============================================================================

# --- Core ---

variable "project" {
  type        = string
  description = "Prefix applied to all resource names and tags."
}

variable "region" {
  type        = string
  description = "AWS region where all resources will be provisioned."
}

# --- Networking ---

variable "vpc_id" {
  type        = string
  description = "ID of the VPC that hosts the pipeline infrastructure."
}

variable "public_subnet_a_id" {
  type        = string
  description = "ID of the public subnet in Availability Zone A."
}

variable "public_subnet_b_id" {
  type        = string
  description = "ID of the public subnet in Availability Zone B (required for Multi-AZ RDS)."
}

# --- Source MySQL Database ---

variable "db_sg_id" {
  type        = string
  description = "Security group ID attached to the source MySQL RDS instance."
}

variable "source_host" {
  type        = string
  description = "Endpoint address of the source MySQL database."
}

variable "source_port" {
  type        = number
  default     = 3306
  description = "Port of the source MySQL database."
}

variable "source_database" {
  type        = string
  default     = "classicmodels"
  description = "Database schema name to extract from the source MySQL instance."
}

variable "source_username" {
  type        = string
  sensitive   = true
  description = "Username for the source MySQL database."
}

variable "source_password" {
  type        = string
  sensitive   = true
  description = "Password for the source MySQL database."
}

# --- Streaming & Inference ---

variable "kinesis_stream_arn" {
  type        = string
  description = "ARN of the upstream Kinesis Data Stream supplying real-time events."
}

variable "inference_api_url" {
  type        = string
  description = "URL of the inference Lambda function that serves recommendation vectors."
}

# --- S3 Buckets ---

variable "ml_artifacts_bucket" {
  type        = string
  description = "Name of the S3 bucket containing pre-computed ML embeddings (managed by the Data Science team)."
}

variable "data_lake_bucket" {
  type        = string
  description = "Name of the S3 bucket used as the ML training data lake."
}

variable "scripts_bucket" {
  type        = string
  description = "Name of the S3 bucket that stores the Glue ETL script."
}

variable "recommendations_bucket" {
  type        = string
  description = "Name of the S3 bucket where Firehose delivers recommendation payloads."
}
