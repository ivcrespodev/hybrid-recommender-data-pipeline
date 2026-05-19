# ============================================================================
# Description: Serverless Compute Vector Ingest and Transform Engine
# Purpose: Compiles source files and deploys inline streaming transformation Lambdas
# Framework: AWS Lambda Serverless execution framework
# ============================================================================

# 1. Compile core application logic source files into target deployment packages
data "archive_file" "transformation_lambda" {
  type        = "zip"
  source_file = "${path.root}/assets/transformation_lambda/main.py"
  output_path = "${path.root}/assets/transformation_lambda/lambda.zip"
}

# 2. Serverless event processor orchestrating inline model inferences
resource "aws_lambda_function" "transformation_lambda" {
  function_name = "${var.project}-stream-transformation-handler"
  description   = "Real-time stream processing worker executing inline item-to-item and user-to-item similarity lookups."
  
  architectures = ["arm64"]
  runtime       = "python3.12"
  handler       = "main.lambda_handler"
  role          = aws_iam_role.transformation_lambda_role.arn

  package_type = "Zip"
  filename     = data.archive_file.transformation_lambda.output_path

  # Operational baseline scale sizing variables
  memory_size = 128
  timeout     = 60

  ephemeral_storage {
    size = 512
  }

  # Observability and distributed log tracing configurations
  tracing_config {
    mode = "PassThrough"
  }

  # Dynamic injection of operational configuration variables
  environment {
    variables = {
      URL_LAMBDA_INFERENCE = var.inference_api_url
      ITEM_LIMIT           = "5"
      RANDOM_SEED          = "42"
    }
  }

  # Tracks code package mutations cryptographically to prompt rolling upgrades
  source_code_hash = data.archive_file.transformation_lambda.output_base64sha256
}
