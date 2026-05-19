# ============================================================================
# Description: Global Core Infrastructure Orchestration Manifest
# System Type: Hybrid Lambda Processing Architecture (Batch & Streaming)
# Provider Core Constraints: HashiCorp AWS & Archive Modules
# ============================================================================

provider "aws" {
  region = var.region
}

# ----------------------------------------------------------------------------
# 1. Cold Path Layer: Batch Ingestion and Distributed ETL Feature Engineering
# ----------------------------------------------------------------------------
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

# ----------------------------------------------------------------------------
# 2. Storage Analytical Core: Relational Database Instance with Vector Spatial Search
# ----------------------------------------------------------------------------
module "vector_db" {
  source = "./modules/vector-db"

  project            = var.project
  region             = var.region
  vpc_id             = var.vpc_id
  public_subnet_a_id = var.public_subnet_a_id
  public_subnet_b_id = var.public_subnet_b_id

  # Ensure the baseline operational store contexts are stable before provisioning
  depends_on = [module.etl]
}

# ----------------------------------------------------------------------------
# 3. Hot Path Layer: Real-Time Event Ingestion and Serverless Stream Transformation
# ----------------------------------------------------------------------------
module "streaming_inference" {
  source = "./modules/streaming-inference"

  project                = var.project
  region                 = var.region
  kinesis_stream_arn     = var.kinesis_stream_arn
  inference_api_url      = var.inference_api_url
  recommendations_bucket = var.recommendations_bucket

  # Restrict creation until the target Vector Database lookup parameters are online
  depends_on = [module.vector_db]
}
