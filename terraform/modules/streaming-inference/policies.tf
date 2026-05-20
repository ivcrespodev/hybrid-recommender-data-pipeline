# ==============================================================================
# Streaming Inference Module — IAM Policy Documents
# ==============================================================================

data "aws_caller_identity" "current" {}

# Trust policy: allow Kinesis Data Firehose to assume the delivery role
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

# Permission policy for the Firehose delivery role
data "aws_iam_policy_document" "firehose_role_policy" {

  # Write recommendation payloads to the S3 sink
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

  # Invoke the transformation Lambda for inline inference enrichment
  statement {
    sid    = "AllowServerlessComputeInvocation"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration"
    ]
    resources = [
      aws_lambda_function.transformation_lambda.arn,
      "${aws_lambda_function.transformation_lambda.arn}:$LATEST"
    ]
  }

  # Write delivery telemetry to CloudWatch Logs
  statement {
    sid    = "AllowCloudWatchLogsDeliveryTelemetry"
    effect = "Allow"
    actions = ["logs:PutLogEvents"]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/${var.project}-delivery-stream:*"
    ]
  }

  # Consume events from the upstream Kinesis Data Stream
  statement {
    sid    = "AllowUpstreamKinesisDataIngestion"
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    resources = [var.kinesis_stream_arn]
  }
}

# Trust policy: allow Lambda to assume the transformation role
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
