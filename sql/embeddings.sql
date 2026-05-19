-- ============================================================================
-- Description: Relational Vector Store Schema & Data Ingestion Pipeline
-- Extensions: aws_s3 (S3 connectivity), vector (pgvector spatial search)
-- Dimensions: 32-dimensional dense embeddings for cold-start recommendations
-- ============================================================================

-- 1. Initialize core vector and cloud infrastructure extensions
CREATE EXTENSION IF NOT EXISTS aws_s3 CASCADE;
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Clean up existing operational tables to avoid ingestion conflicts
DROP TABLE IF EXISTS item_emb;
DROP TABLE IF EXISTS user_emb;

-- 3. Construct target dimension matrix structures
CREATE TABLE IF NOT EXISTS item_emb (
    id VARCHAR PRIMARY KEY, 
    embedding VECTOR(32)
);

CREATE TABLE IF NOT EXISTS user_emb (
    id INT PRIMARY KEY, 
    embedding VECTOR(32)
);

-- 4. Bulk import product-space embeddings directly from the S3 ML Artifacts repository
SELECT aws_s3.table_import_from_s3(
   'item_emb', 
   'id,embedding', 
   '(format csv, header true)',
   '{{ML_ARTIFACTS_BUCKET}}',
   'embeddings/item_embeddings.csv', 
   'us-east-1'
);

-- 5. Bulk import user-behavior embeddings directly from the S3 ML Artifacts repository
SELECT aws_s3.table_import_from_s3(
   'user_emb', 
   'id,embedding', 
   '(format csv, header true)',
   '{{ML_ARTIFACTS_BUCKET}}',
   'embeddings/user_embeddings.csv', 
   'us-east-1'
);