# ==============================================================================
# Streaming Inference Module — IAM Roles & Policy Attachments
# ==============================================================================

# Kinesis Data Firehose execution role
resource "aws_iam_role" "firehose_role" {
  name        = "${var.project}-firehose-execution-role"
  description = "Execution role for Kinesis Data Firehose — consumes stream events, invokes transformation Lambda, and writes to S3."

  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_iam_role_policy" "firehose_role_policy" {
  name   = "${var.project}-firehose-resource-access-policy"
  role   = aws_iam_role.firehose_role.id
  policy = data.aws_iam_policy_document.firehose_role_policy.json
}

# Lambda transformation function execution role
resource "aws_iam_role" "transformation_lambda_role" {
  name        = "${var.project}-stream-transform-lambda-role"
  description = "Execution role for the stream transformation Lambda function."

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Attach the AWS-managed basic execution policy for CloudWatch Logs access
resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.transformation_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
