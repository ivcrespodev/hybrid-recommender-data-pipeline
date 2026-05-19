# End-to-End Hybrid Recommender Data Pipeline (Batch & Streaming)

This repository contains the Infrastructure as Code (IaC) manifests, SQL scripts, and configuration helpers required to deploy a decoupled, production-ready machine learning data pipeline on AWS. The system isolates historical batch feature preparation from real-time streaming recommendation delivery to meet high-scale stakeholder requirements.

## Architecture Overview

The system implements a lambda-style processing architecture divided into two core operational flows:

1. **Batch ETL Pipeline (Cold Path):** 
   * **Ingestion:** Extracts historical operational logs and user behavioral metadata from an Amazon RDS MySQL production database.
   * **Processing:** Triggers a serverless distributed AWS Glue ETL job (`hybrid-recommender-etl-job`) to execute transformations and partition output data by customer.
   * **Storage:** Dumps structured ML training datasets into an Amazon S3 Data Lake bucket.

2. **Streaming ETL Pipeline (Hot Path):**
   * **Ingestion:** Captures live, low-latency online user session events concurrently via Amazon Kinesis Data Streams.
   * **Processing & Inference:** Amazon Kinesis Data Firehose intercepts the stream, buffering data and invoking an AWS Lambda function (`recommender-model-inference`). This serverless layer loads a pre-trained PyTorch model and executes real-time vector-similarity lookups against a vector store.
   * **Storage & Serving:** Recommendations are processed via an Amazon Aurora/RDS PostgreSQL instance utilizing the `pgvector` extension, while raw target logs are backed up sequentially in an S3 Recommendation Bucket partitioned by date (Year/Month/Day/Hour).

## Data Schema & Sources
* **Source Transactional DB:** Amazon RDS MySQL instance featuring the standard `classicmodels` schema, extended with a synthesized user-product `ratings` table (1-5 scale) to feed downstream algorithms.
* **Machine Learning Artifacts (Pre-provided):** 
  > 💡 **Architectural Note:** The Machine Learning models and vector scaling assets used in this architecture are consumed as upstream dependencies pre-computed by the Data Science team inside an isolated S3 artifacts bucket. This repository focuses entirely on the production data engineering pipelines required to store, route, and serve them.
* **Vector Store:** Amazon Aurora/RDS PostgreSQL using `pgvector` to store and query multi-dimensional `vector(32)` user and item embeddings.

## Repository Structure
```text
├── data/               # Local data directory (skeleton structure filtered via .gitignore)
├── sql/                # Target DDL and bulk S3-to-PostgreSQL vector ingestion scripts
├── terraform/          # Modularized IaC manifests (etl, vector_db, and streaming modules)
├── scripts/            # Shell scripts for automated environment and session setups
├── .env.example        # Reference template for local environment variables
└── .gitignore          # Rules to exclude local tfstate, credentials, and cache blocks
```

## Deployment Steps

### Prerequisites
* AWS CLI configured with appropriate IAM administrative permissions.
* Terraform CLI (v1.5+ recommended).
* PostgreSQL client (`psql`) installed and accessible via terminal.
* `jq` command-line JSON processor.

### 1. Environment Setup & Ingestion
1. Initialize local environment properties:
   ```bash
   cp .env.example .env
   # Populate your .env file with your specific AWS account variables
   source ./scripts/setup.sh
   ```
2. Navigate to the IaC root, uncomment the `etl` module block inside `terraform/main.tf` (and its outputs in `outputs.tf`), and apply changes:
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```
3. Trigger the ingestion batch workflow on AWS Glue via CLI:
   ```bash
   aws glue start-job-run --job-name hybrid-recommender-etl-job | jq -r '.JobRunId'
   ```

### 2. Provisioning & Initializing the Vector Database
1. In `terraform/main.tf`, uncomment the `vector_db` module block (and its outputs in `outputs.tf`).
2. Apply changes to deploy the Aurora/RDS PostgreSQL instance:
   ```bash
   terraform apply
   ```
3. Extract credentials for database connection:
   ```bash
   terraform output vector_db_master_username
   terraform output vector_db_master_password
   terraform output vector_db_host
   ```
4. Open `sql/embeddings.sql` and substitute the `<BUCKET_NAME>` placeholders with your assigned artifacts bucket name (`recommender-ml-artifacts`).
5. Feed the pre-computed embeddings into PostgreSQL using the interactive shell:
   ```bash
   psql --host=<VectorDBHost> --username=postgres --password --port=5432
   # Inside the psql shell:
   \c postgres;
   \i '../sql/embeddings.sql'
   \q
   ```

### 3. Activating the Streaming Pipeline
1. Update the Environment Variables (`VECTOR_DB_HOST`, `VECTOR_DB_USER`, `VECTOR_DB_PASSWORD`) inside the AWS Lambda console for `recommender-model-inference`.
2. In `terraform/main.tf`, uncomment the final `streaming_inference` module block.
3. Deploy the real-time streaming framework components:
   ```bash
   terraform apply
   ```
4. Verify pipeline logs and incoming partitioned payloads inside the target S3 recommendation bucket or CloudWatch log groups (`/aws/lambda/stream-transformation-lambda`).
