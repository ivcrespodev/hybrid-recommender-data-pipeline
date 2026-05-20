# ==============================================================================
# Vector DB Module — IAM Policy Documents
# ==============================================================================

# Trust policy: allow RDS to assume the S3 import role
data "aws_iam_policy_document" "rds_assume_role" {
  statement {
    sid    = "AllowRDSToAssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Permission policy: allow the RDS instance to read embeddings from S3
# This is required for aws_s3.table_import_from_s3() calls in embeddings.sql
data "aws_iam_policy_document" "rds_s3_import_policy" {
  statement {
    sid    = "AllowS3EmbeddingsRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.ml_artifacts_bucket}",
      "arn:aws:s3:::${var.ml_artifacts_bucket}/*"
    ]
  }
}
