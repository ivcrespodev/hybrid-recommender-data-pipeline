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
# Depends on ETL so the data lake exists before the vector DB is populated
# ------------------------------------------------------------------------------
module "vector_db" {
  source = "./modules/vector-db"

  project             = var.project
  region              = var.region
  vpc_id              = var.vpc_id
  public_subnet_a_id  = var.public_subnet_a_id
  public_subnet_b_id  = var.public_subnet_b_id
  ml_artifacts_bucket = var.ml_artifacts_bucket

  depends_on = [module.etl]
}

# ------------------------------------------------------------------------------
# Module 3 — Hot Path: Real-Time Streaming & Inference
# Depends on vector_db so embeddings are available before stream processing starts
# ------------------------------------------------------------------------------
module "streaming_inference" {
  source = "./modules/streaming-inference"

  project                = var.project
  region                 = var.region
  kinesis_stream_arn     = var.kinesis_stream_arn
  inference_api_url      = var.inference_api_url
  recommendations_bucket = var.recommendations_bucket

  depends_on = [module.vector_db]
}
