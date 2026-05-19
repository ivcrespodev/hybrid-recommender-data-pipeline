# ============================================================================
# Description: Identity & Access Management (IAM) Profiles for Streaming Layer
# Security Principle: Least Privilege Access (LPA) for Kinesis & Lambda Engines
# ============================================================================

# 1. Delivery Execution Role enabling Kinesis Data Firehose trusted entity handshakes
resource "aws_iam_role" "firehose_role" {
  name        = "${var.project}-firehose-execution-role"
  description = "IAM Execution Role allowing Kinesis Data Firehose to consume metrics streams, trigger transformation Lambdas, and dump analytics outputs into S3."
  
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

# 2. Inline boundary access policy coupling structural capabilities to the Firehose profile
resource "aws_iam_role_policy" "firehose_role_policy" {
  name = "${var.project}-firehose-resource-access-policy"
  role = aws_iam_role.firehose_role.id
  
  policy = data.aws_iam_policy_document.firehose_role_policy.json
}

# 3. Compute Execution Role defining secure trust entities for Serverless functions
resource "aws_iam_role" "transformation_lambda_role" {
  name        = "${var.project}-stream-transform-lambda-role"
  description = "IAM Execution Role granting the serverless stream transformation function capabilities to write tracking telemetry to CloudWatch Logs."
  
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# 4. Standard structural attachment linking cloud telemetry logging baseline to the compute profile
resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  role       = aws_iam_role.transformation_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


