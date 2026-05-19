# ============================================================================
# Description: Identity & Access Management (IAM) Profiles for Vector Store
# Security Principle: Least Privilege Access (LPA) for Bulk Data Ingestion
# Feature: Authorizes Amazon RDS Native Extensions to Import Datasets from S3
# ============================================================================

# 1. Execution Role enabling trusted entity handshakes between RDS and Amazon S3
resource "aws_iam_role" "rds_role" {
  name        = "${var.project}-rds-s3-ingestion-role"
  description = "IAM Database Integration Role allowing the relational PostgreSQL cluster to assume access policies and read bulk embeddings files directly from S3 repositories."
  
  assume_role_policy = data.aws_iam_policy_document.rds_assume_role.json
}

# 2. Native association linking the execution role capabilities to the active database engine
resource "aws_db_instance_role_association" "rds_role_association" {
  db_instance_identifier = aws_db_instance.master_db.identifier
  feature_name           = "s3Import"
  role_arn               = aws_iam_role.rds_role.arn
}

