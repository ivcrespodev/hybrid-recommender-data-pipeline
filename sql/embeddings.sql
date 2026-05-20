-- ==============================================================================
-- Vector Store Schema & Embedding Ingestion Pipeline
-- Extensions: aws_s3 (S3 connectivity), vector (pgvector spatial search)
-- Dimensions: 32-dimensional dense embeddings for cold-start recommendations
--
-- Usage: Replace <ML_ARTIFACTS_BUCKET> with your actual S3 bucket name before
--        running, or use the sed command shown in the README:
--          sed -i "s/<ML_ARTIFACTS_BUCKET>/${ML_ARTIFACTS_BUCKET}/g" sql/embeddings.sql
-- ==============================================================================

-- 1. Initialize required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS aws_s3 CASCADE;
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Drop and recreate tables to ensure a clean ingestion state
DROP TABLE IF EXISTS item_emb;
DROP TABLE IF EXISTS user_emb;

CREATE TABLE IF NOT EXISTS item_emb (
    id        VARCHAR PRIMARY KEY,
    embedding VECTOR(32)
);

CREATE TABLE IF NOT EXISTS user_emb (
    id        INT PRIMARY KEY,
    embedding VECTOR(32)
);

-- 3. Bulk-import item embeddings from the S3 ML artifacts repository
SELECT aws_s3.table_import_from_s3(
    'item_emb',
    'id,embedding',
    '(format csv, header true)',
    '<ML_ARTIFACTS_BUCKET>',
    'embeddings/item_embeddings.csv',
    'us-east-1'
);

-- 4. Bulk-import user embeddings from the S3 ML artifacts repository
SELECT aws_s3.table_import_from_s3(
    'user_emb',
    'id,embedding',
    '(format csv, header true)',
    '<ML_ARTIFACTS_BUCKET>',
    'embeddings/user_embeddings.csv',
    'us-east-1'
);
