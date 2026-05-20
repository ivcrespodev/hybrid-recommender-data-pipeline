# ==============================================================================
# ETL Module — Input Variable Declarations
# ==============================================================================

variable "project" {
  type        = string
  description = "Prefix applied to all resource names and tags."
}

variable "region" {
  type        = string
  description = "AWS region where ETL resources are provisioned."
}

variable "public_subnet_a_id" {
  type        = string
  description = "ID of the public subnet used by the Glue JDBC connection."
}

variable "db_sg_id" {
  type        = string
  description = "Security group ID attached to the source MySQL RDS instance."
}

variable "host" {
  type        = string
  description = "Endpoint address of the source MySQL database."
}

variable "port" {
  type        = number
  default     = 3306
  description = "Port of the source MySQL database."
}

variable "database" {
  type        = string
  description = "Schema name to extract from the source MySQL instance."
}

variable "username" {
  type        = string
  sensitive   = true
  description = "Username for the source MySQL database."
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Password for the source MySQL database."
}

variable "data_lake_bucket" {
  type        = string
  description = "Name of the S3 bucket used as the ML training data lake."
}

variable "scripts_bucket" {
  type        = string
  description = "Name of the S3 bucket that stores the Glue ETL script."
}

variable "scripts_key" {
  type        = string
  default     = "etl-job.py"
  description = "S3 object key of the Glue PySpark script inside the scripts bucket."
}
