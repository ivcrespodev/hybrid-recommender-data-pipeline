# ==============================================================================
# ETL Module — IAM Role & Policy Attachment
# ==============================================================================

resource "aws_iam_role" "glue_role" {
  name        = "${var.project}-glue-execution-role"
  description = "Execution role assumed by AWS Glue ETL jobs."

  assume_role_policy = data.aws_iam_policy_document.glue_base_policy.json
}

resource "aws_iam_role_policy" "task_role_policy" {
  name   = "${var.project}-glue-resource-access-policy"
  role   = aws_iam_role.glue_role.id
  policy = data.aws_iam_policy_document.glue_access_policy.json
}
