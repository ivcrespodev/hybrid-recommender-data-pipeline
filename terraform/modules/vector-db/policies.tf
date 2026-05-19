# ============================================================================
# Description: Identity & Access Management (IAM) Policy Documents
# Purpose: Establishes a secure trust relationship boundary for Amazon RDS
# Scope: Authorizes the RDS engine service principal to assume role actions
# ============================================================================

# 1. Define trusted entity configuration permitting standard RDS handshakes
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
