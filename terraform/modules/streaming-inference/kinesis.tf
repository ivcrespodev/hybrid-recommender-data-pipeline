# ==============================================================================
# Streaming Inference Module — Kinesis Data Firehose & CloudWatch Logs
# ==============================================================================

# CloudWatch log group for Firehose delivery telemetry
resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "/aws/kinesisfirehose/${var.project}-delivery-stream"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "S3DeliveryTelemetry"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
}

# Firehose delivery stream: consumes Kinesis events, invokes Lambda for
# inline inference enrichment, and delivers payloads to S3
resource "aws_kinesis_firehose_delivery_stream" "extended_s3_stream" {
  name        = "${var.project}-delivery-stream"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = var.kinesis_stream_arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = "arn:aws:s3:::${var.recommendations_bucket}"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
    }

    # Invoke the transformation Lambda on each buffered batch
    processing_configuration {
      enabled = true

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
