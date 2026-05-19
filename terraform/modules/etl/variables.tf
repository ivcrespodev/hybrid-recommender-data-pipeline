# ============================================================================
# Description: ETL Module Variable Definitions & Structural Input Contract
# Scope: Configures relational endpoints, network anchors, and storage keys
# ============================================================================

variable "project" {
  type        = string
  description = "Enterprise deployment namespace prefix used to tag and isolate infrastructure resources."
}

variable "region" {
  type        = string
  description = "Target geographical AWS Region where the distributed computing cluster will be provisioned."
}

variable "public_subnet_a_id" {
  type        = string
  description = "The target public subnet identifier utilized to allocate the AWS Glue Elastic Network Interfaces (ENI)."
}

variable "db_sg_id" {
  type        = string
  description = "The reference operational security group identifier guarding ingress traffic to the relational data node."
}

variable "host" {
  type        = string
  description = "The network connection string endpoint address of the source relational database node."
}

variable "port" {
  type        = number
  default     = 3306
  description = "The network communication port utilized to access the origin database instance (Default: 3306 MySQL)."
}

variable "database" {
  type        = string
  description = "The targeted operational relational database schema container name holding transactional source logs."
}

variable "username" {
  type        = string
  description = "The administrative connection database user principal account name authorized to extract tables."
}

variable "password" {
  type        = string
  sensitive   = true
  description = "The secret connection database security credential accompanying the administrative user principal."
}

variable "data_lake_bucket" {
  type        = string
  description = "The unique identifier designation mapping the centralized Amazon S3 Data Lake analytical target."
}

variable "scripts_bucket" {
  type        = string
  description = "The unique identifier mapping the Amazon S3 script repository hosting pipeline engine code."
}

variable "scripts_key" {
  type        = string
  default     = "etl-job.py"
  description = "The exact file path string pointing to the deployment package location within the scripts repository bucket."
}
