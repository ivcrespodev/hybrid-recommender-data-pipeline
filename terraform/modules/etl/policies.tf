# ==============================================================================
# ETL Module — IAM Policy Documents
# ==============================================================================

data "aws_caller_identity" "current" {}

# Trust policy: allow AWS Glue to assume the execution role
data "aws_iam_policy_document" "glue_base_policy" {
  statement {
    sid    = "AllowGlueToAssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Permission policy: least-privilege access for Glue job execution
data "aws_iam_policy_document" "glue_access_policy" {

  # CloudWatch Logs — write ETL job output and error logs
  statement {
    sid    = "AllowCloudWatchLogsOperations"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws-glue/*"]
  }

  # Glue Data Catalog — synchronize schema metadata
  statement {
    sid    = "AllowGlueDataCatalogManagement"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:CreateDatabase",
      "glue:UpdateDatabase",
      "glue:GetTable",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:GetPartitions",
      "glue:BatchCreatePartition",
      "glue:BatchGetPartition"
    ]
    # Glue catalog ARNs do not support resource-level restrictions on these actions
    resources = ["*"]
  }

  # EC2 / VPC — attach ENIs so Glue can reach the MySQL RDS endpoint
  statement {
    sid    = "AllowVPCNetworkInterfaceConfiguration"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs"
    ]
    # Describe/Delete ENI actions require * at resource level
    resources = ["*"]
  }

  # S3 — read the ETL script and write Parquet output to the data lake
  statement {
    sid    = "AllowTargetS3BucketDataOps"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.data_lake_bucket}",
      "arn:aws:s3:::${var.data_lake_bucket}/*",
      "arn:aws:s3:::${var.scripts_bucket}",
      "arn:aws:s3:::${var.scripts_bucket}/*"
    ]
  }
}
