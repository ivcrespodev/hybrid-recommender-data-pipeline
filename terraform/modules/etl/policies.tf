# ============================================================================
# Description: Fine-Grained IAM Security Policy Document Manifests
# Security Principle: Principle of Least Privilege (PoLP) for AWS Glue Jobs
# ============================================================================

# 1. Fetch current active deployment account context telemetry
data "aws_caller_identity" "current" {}

# 2. Define trusted entity service principal relationships for AWS Glue core engine
data "aws_iam_policy_document" "glue_base_policy" {
  statement {
    sid    = "AllowGlueToAssumeRole"
    effect = "Allow"

    principals {
      identifiers = ["glue.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

# 3. Fine-grained authorization boundaries limiting resource mutations
data "aws_iam_policy_document" "glue_access_policy" {
  
  # Group 1: Telemetry Monitoring and Event Tracking Logging Permissions
  statement {
    sid    = "AllowCloudWatchLogsOperations"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws-glue/*"
    ]
  }

  # Group 2: Data Catalog Meta-store Structural Synchronization Permissions
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
    resources = ["*"]
  }

  # Group 3: Isolated Network interface Attachment and Subnet Topology Discovery
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
    resources = ["*"]
  }

  # Group 4: Restricted Storage Operations bounded to the Data Pipeline boundaries
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
