# ============================================================================
# Description: Fine-Grained IAM Security Policy Document Manifests
# Security Principle: Principle of Least Privilege (PoLP) for Streaming Engines
# Scope: Authorizes Kinesis Firehose, Lambda Transformations, and Log Routing
# ============================================================================

# 1. Capture dynamic deployment context metrics
data "aws_caller_identity" "current" {}

# 2. Define trusted entity service principal parameters for Kinesis Data Firehose
data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    sid    = "AllowFirehoseToAssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# 3. Fine-grained resource permission maps exclusively bounded to active pipeline engines
data "aws_iam_policy_document" "firehose_role_policy" {

  # Group 1: Authorize metrics stream synchronization with the analytical S3 bucket
  statement {
    sid    = "AllowTargetS3BucketDeliveryOps"
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${var.recommendations_bucket}",
      "arn:aws:s3:::${var.recommendations_bucket}/*"
    ]
  }

  # Group 2: Authorize inline data enrichment triggering on the ML Transformation Lambda
  statement {
    sid    = "AllowServerlessComputeInvocation"
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration"
    ]

    resources = [
      "${aws_lambda_function.transformation_lambda.arn}",
      "${aws_lambda_function.transformation_lambda.arn}:$LATEST"
    ]
  }

  # Group 3: Authorize telemetry events delivery to designated CloudWatch log streams
  statement {
    sid    = "AllowCloudWatchLogsDeliveryTelemetry"
    effect = "Allow"

    actions = [
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/${var.project}-delivery-stream:*"
    ]
  }

  # Group 4: Authorize upstream message ingestion consumption from Kinesis Data Streams
  statement {
    sid    = "AllowUpstreamKinesisDataIngestion"
    effect = "Allow"

    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]

    resources = [
      var.kinesis_stream_arn
    ]
  }
}

# 4. Define trusted entity service principal parameters for AWS Lambda Compute Node
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    sid    = "AllowLambdaToAssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
