# ==============================================================================
# Global Infrastructure Orchestration
# Architecture: Hybrid Lambda Processing (Batch + Streaming)
# ==============================================================================

provider "aws" {
  region = var.region
}

# ------------------------------------------------------------------------------
# Module 1 — Cold Path: Batch Ingestion & Distributed ETL
# ------------------------------------------------------------------------------
module "etl" {
  source = "./modules/etl"

  project            = var.project
  region             = var.region
  public_subnet_a_id = var.public_subnet_a_id
  db_sg_id           = var.db_sg_id
  host               = var.source_host
  port               = var.source_port
  database           = var.source_database
  username           = var.source_username
  password           = var.source_password
  data_lake_bucket   = var.data_lake_bucket
  scripts_bucket     = var.scripts_bucket
}

# ------------------------------------------------------------------------------
# Module 2 — Vector Store: PostgreSQL with pgvector
# The Glue JDBC connection (etl module) must exist before the vector DB is
# created so that the VPC and subnet context is fully established.
# ------------------------------------------------------------------------------
module "vector_db" {
  source = "./modules/vector-db"

  project             = var.project
  region              = var.region
  vpc_id              = var.vpc_id
  public_subnet_a_id  = var.public_subnet_a_id
  public_subnet_b_id  = var.public_subnet_b_id
  ml_artifacts_bucket = var.ml_artifacts_bucket

  depends_on = [module.etl.glue_connection_name]
}

# ------------------------------------------------------------------------------
# Module 3 — Hot Path: Real-Time Streaming & Inference
# The Firehose delivery stream invokes the transformation Lambda, which calls
# the inference API backed by the vector DB — so both prior modules must be
# fully ready before streaming resources are created.
# ------------------------------------------------------------------------------
module "streaming_inference" {
  source = "./modules/streaming-inference"

  project                = var.project
  region                 = var.region
  kinesis_stream_arn     = var.kinesis_stream_arn
  inference_api_url      = var.inference_api_url
  recommendations_bucket = var.recommendations_bucket

  depends_on = [module.vector_db.vector_db_host]
}
