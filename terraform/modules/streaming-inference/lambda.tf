# ==============================================================================
# Streaming Inference Module — Lambda Transformation Function
# ==============================================================================

# Package main.py into a deployment zip at plan/apply time
data "archive_file" "transformation_lambda" {
  type        = "zip"
  source_file = "${path.root}/assets/transformation_lambda/main.py"
  output_path = "${path.root}/assets/transformation_lambda/lambda.zip"
}

resource "aws_lambda_function" "transformation_lambda" {
  function_name = "${var.project}-stream-transformation-handler"
  description   = "Inline stream processor that performs item-to-item and user-to-item similarity lookups via the inference API."

  architectures = ["arm64"]
  runtime       = "python3.12"
  handler       = "main.lambda_handler"
  role          = aws_iam_role.transformation_lambda_role.arn

  package_type     = "Zip"
  filename         = data.archive_file.transformation_lambda.output_path
  source_code_hash = data.archive_file.transformation_lambda.output_base64sha256

  memory_size = 128
  timeout     = 60

  ephemeral_storage {
    size = 512
  }

  tracing_config {
    mode = "PassThrough"
  }

  environment {
    variables = {
      URL_LAMBDA_INFERENCE = var.inference_api_url
      ITEM_LIMIT           = "5"
      RANDOM_SEED          = "42"
    }
  }
}
