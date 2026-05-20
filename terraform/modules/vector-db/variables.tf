# ==============================================================================
# Vector DB Module — Input Variable Declarations
# ==============================================================================

variable "project" {
  type        = string
  description = "Prefix applied to all resource names and tags."
}

variable "region" {
  type        = string
  description = "AWS region where the RDS instance will be provisioned."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC that will host the RDS instance."
}

variable "public_subnet_a_id" {
  type        = string
  description = "ID of the subnet in Availability Zone A for the RDS subnet group."
}

variable "public_subnet_b_id" {
  type        = string
  description = "ID of the subnet in Availability Zone B for Multi-AZ RDS support."
}

variable "master_username" {
  type        = string
  default     = "postgres"
  description = "Master username for the PostgreSQL instance."
}

variable "ml_artifacts_bucket" {
  type        = string
  default     = ""
  description = "Name of the S3 bucket containing pre-computed ML embeddings. Required for the RDS S3 import role."
}
