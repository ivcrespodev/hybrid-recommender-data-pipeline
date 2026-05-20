# ==============================================================================
# Vector DB Module — IAM Role & Policy Attachments
# ==============================================================================

# Execution role assumed by RDS to perform S3 imports via aws_s3 extension
resource "aws_iam_role" "rds_role" {
  name        = "${var.project}-rds-s3-ingestion-role"
  description = "IAM role allowing the RDS PostgreSQL instance to import embedding files from S3."

  assume_role_policy = data.aws_iam_policy_document.rds_assume_role.json
}

# Attach the S3 read policy to the role so the import actually works
resource "aws_iam_role_policy" "rds_s3_import_policy" {
  name   = "${var.project}-rds-s3-import-policy"
  role   = aws_iam_role.rds_role.id
  policy = data.aws_iam_policy_document.rds_s3_import_policy.json
}

# Associate the role with the RDS instance for the s3Import feature
resource "aws_db_instance_role_association" "rds_role_association" {
  db_instance_identifier = aws_db_instance.master_db.identifier
  feature_name           = "s3Import"
  role_arn               = aws_iam_role.rds_role.arn
}
