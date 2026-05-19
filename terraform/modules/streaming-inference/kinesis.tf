# ============================================================================
# Description: Real-Time Streaming Ingestion & Delivery Service Engine
# Target Layer: Streaming Pipeline / Real-Time Data Transformations
# Orchestration: Amazon Kinesis Data Firehose to Amazon S3 Sink
# ============================================================================

# 1. CloudWatch Log Analytics Infra mapping for delivery auditing telemetry
resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "/aws/kinesisfirehose/${var.project}-delivery-stream"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "S3DeliveryTelemetry"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
}

# 2. Main Delivery Router intercepting events and orchestrating inline transformations
resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "${var.project}-delivery-stream"
  destination = "extended_s3"

  # Stream Ingestion Anchor binding upstream transaction logs
  kinesis_source_configuration {
    kinesis_stream_arn = var.kinesis_stream_arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  # Extended S3 Engine mapping inline transformation logic and backup policies
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = "arn:aws:s3:::${var.recommendations_bucket}"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
    }

    # Intercept event payload data and divert buffer chunks to the ML Inference Lambda
    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.transformation_lambda.arn}:$LATEST"
        }
      }
    }
  }
}

