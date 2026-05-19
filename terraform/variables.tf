# ============================================================================
# Description: Global Root Infrastructure Variable Declarations (Input Contract)
# Scope: Centralizes network topologies, source clusters, and target storage sinks
# ============================================================================

# ----------------------------------------------------------------------------
# Core Context Configurations
# ----------------------------------------------------------------------------
variable "project" {
  type        = string
  description = "Enterprise deployment namespace prefix used to tag, isolate, and group infrastructure resources globally."
}

variable "region" {
  type        = string
  description = "Target geographical AWS Region where the core analytical and streaming nodes will be provisioned."
}

# ----------------------------------------------------------------------------
# Network Boundary Configurations
# ----------------------------------------------------------------------------
variable "vpc_id" {
  type        = string
  description = "The central Virtual Private Cloud (VPC) identifier acting as the isolated network boundary for the architecture."
}

variable "public_subnet_a_id" {
  type        = string
  description = "The target public subnet identifier within Availability Zone A utilized for Multi-AZ cluster routing paths."
}

variable "public_subnet_b_id" {
  type        = string
  description = "The target public subnet identifier within Availability Zone B utilized to fulfill high-availability Multi-AZ configurations."
}

# ----------------------------------------------------------------------------
# Source Operational Store Parameters (MySQL Engine)
# ----------------------------------------------------------------------------
variable "db_sg_id" {
  type        = string
  description = "The reference operational security group identifier guarding ingress traffic to the relational data node."
}

variable "source_host" {
  type        = string
  description = "The network connection string endpoint address of the source transactional database node."
}

variable "source_port" {
  type        = number
  default     = 3306
  description = "The network communication port utilized to access the origin database instance (Default: 3306 MySQL)."
}

variable "source_database" {
  type        = string
  default     = "classicmodels"
  description = "The targeted operational relational database schema container name holding transactional source logs."
}

variable "source_username" {
  type        = string
  sensitive   = true
  description = "The administrative connection database user principal account name authorized to extract transactional schemas."
}

variable "source_password" {
  type        = string
  sensitive   = true
  description = "The secret connection database security credential accompanying the administrative user principal."
}

# ----------------------------------------------------------------------------
# Streaming and Serverless Context Inputs
# ----------------------------------------------------------------------------
variable "kinesis_stream_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) identifying the upstream Kinesis Data Stream capturing real-time transaction logs."
}

variable "inference_api_url" {
  type        = string
  description = "The HTTP/HTTPS connection URL endpoint pointing to the remote serverless inference API hosting the machine learning models."
}

# ----------------------------------------------------------------------------
# Centralized S3 Persistence Sinks
# ----------------------------------------------------------------------------
variable "data_lake_bucket" {
  type        = string
  description = "The unique identifier designation mapping the centralized Amazon S3 Data Lake analytical target."
}

variable "scripts_bucket" {
  type        = string
  description = "The unique identifier mapping the Amazon S3 script repository hosting pipeline engine code."
}

variable "recommendations_bucket" {
  type        = string
  description = "The unique identification name mapping the destination Amazon S3 bucket used as the real-time recommendations data store sink."
}
