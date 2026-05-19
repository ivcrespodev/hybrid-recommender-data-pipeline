# ============================================================================
# Description: Identity & Access Management (IAM) Profiles for Batch Layer
# Security Principle: Least Privilege Access (LPA) for AWS Glue Execution
# ============================================================================

# 1. Execution Role defining trusted entity service principal permissions
resource "aws_iam_role" "glue_role" {
  name        = "${var.project}-glue-execution-role"
  description = "IAM Execution Role allowing AWS Glue ETL jobs to assume service principles and interact with provisioned VPC networks."
  
  assume_role_policy = data.aws_iam_policy_document.glue_base_policy.json
}

# 2. Inline security boundary policy mapping fine-grained resource access privileges
resource "aws_iam_role_policy" "task_role_policy" {
  name = "${var.project}-glue-resource-access-policy"
  role = aws_iam_role.glue_role.id
  
  policy = data.aws_iam_policy_document.glue_access_policy.json
}
