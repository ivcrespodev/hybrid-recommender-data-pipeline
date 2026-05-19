# ============================================================================
# Description: Vector DB Module Variable Definitions & Structural Input Contract
# Scope: Configures network boundaries, subnets, and database credentials
# ============================================================================

variable "project" {
  type        = string
  description = "Enterprise deployment namespace prefix used to tag, isolate, and group database infrastructure resources."
}

variable "region" {
  type        = string
  description = "Target geographical AWS Region where the relational vector instance and its subnet groups will be provisioned."
}

variable "vpc_id" {
  type        = string
  description = "The central Virtual Private Cloud (VPC) identifier acting as the isolated network boundary for the database."
}

variable "public_subnet_a_id" {
  type        = string
  description = "The target public subnet identifier within Availability Zone A utilized for Multi-AZ clustering routing paths."
}

variable "public_subnet_b_id" {
  type        = string
  description = "The target public subnet identifier within Availability Zone B utilized to fulfill high-availability Multi-AZ requirements."
}

variable "master_username" {
  type        = string
  default     = "postgres"
  description = "The master administrative user principal account name authorized to manage database schemas and vector spatial indices."
}
