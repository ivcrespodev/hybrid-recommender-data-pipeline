# Hybrid Recommender Data Pipeline (Batch & Streaming)

This repository contains the Infrastructure as Code (IaC) manifests, SQL scripts,
and configuration helpers required to deploy a production-grade machine learning
data pipeline on AWS. The system separates historical batch feature preparation
from real-time streaming recommendation delivery.

---

## Architecture Overview

The pipeline implements a lambda-style processing architecture with two operational flows:

**Batch ETL Pipeline (Cold Path)**
- Extracts historical ratings and product data from a source RDS MySQL database.
- Runs a distributed AWS Glue PySpark job to join and transform the data.
- Stores partitioned ML training datasets in an S3 Data Lake bucket.

**Streaming Pipeline (Hot Path)**
- Captures live user session events via Amazon Kinesis Data Streams.
- Kinesis Data Firehose buffers events and invokes an AWS Lambda function for
  real-time vector-similarity inference against a PostgreSQL vector store.
- Delivers enriched recommendation payloads to a partitioned S3 bucket
  (partitioned by Year/Month/Day/Hour).

---

## Pre-Provisioned Infrastructure

The following AWS resources are assumed to exist in your account before deploying
this pipeline. They are managed externally (by platform or data science teams) and
are **not created by the Terraform code in this repository**.

| Resource | Expected identifier |
|---|---|
| RDS MySQL instance (source ODS) | `recommender-system-rds` |
| MySQL schema | `classicmodels` (includes the `ratings` table) |
| Kinesis Data Stream | `recommender-system-kinesis-data-stream` |
| Lambda inference function | `recommender-system-model-inference` |
| S3 ML artifacts bucket | `recommender-system-<ACCOUNT_ID>-<REGION>-ml-artifacts` |
| VPC with two public subnets | Tagged `Environment=Production`, `Type=PublicA` / `Type=PublicB` |

The ML artifacts bucket contains the following structure, produced by the Data
Science team after training:

```
.
├── embeddings/
│   ├── item_embeddings.csv
│   └── user_embeddings.csv
├── model/
│   └── best_model.pth
└── scalers/
    ├── item_ohe.pkl
    ├── item_std_scaler.pkl
    ├── user_ohe.pkl
    └── user_std_scaler.pkl
```

---

## Repository Structure

```
├── data/                            # Local data directory (git-ignored)
├── sql/
│   └── embeddings.sql               # DDL + S3-to-PostgreSQL embedding ingestion
├── terraform/
│   ├── backend.tf                   # State backend + provider version constraints
│   ├── main.tf                      # Root module — wires etl, vector-db, streaming-inference
│   ├── variables.tf                 # Root input variable declarations
│   ├── outputs.tf                   # Root output declarations
│   ├── assets/
│   │   ├── glue_job/etl-job.py      # PySpark ETL script for AWS Glue
│   │   └── transformation_lambda/   # Lambda deployment package (main.py + lambda.zip)
│   └── modules/
│       ├── etl/                     # Glue catalog, connection, crawler, job + IAM
│       ├── vector-db/               # RDS PostgreSQL + pgvector + IAM
│       └── streaming-inference/     # Firehose, Lambda, CloudWatch + IAM
├── scripts/
│   └── setup.sh                     # Resolves pre-provisioned resource IDs → TF_VAR_*
├── .env.example                     # Environment variable template
└── .gitignore
```

---

## Prerequisites

- AWS CLI configured with IAM permissions sufficient to create Glue, RDS, Lambda,
  Kinesis Firehose, IAM roles, S3 buckets, and CloudWatch log groups.
- Terraform CLI v1.5 or later.
- PostgreSQL client (`psql`) accessible from your terminal.
- `jq` command-line JSON processor.
- All pre-provisioned resources listed above must be active and reachable.

---

## Deployment

### Step 1 — Configure local environment

```bash
cp .env.example .env
```

Open `.env` and fill in:
- `AWS_ACCOUNT_ID` — your 12-digit AWS account ID.
- `AWS_REGION` — the region where all resources live (default: `us-east-1`).
- `ML_ARTIFACTS_BUCKET` — the name of the pre-provisioned ML artifacts bucket.
- `DB_SOURCE_USER` / `DB_SOURCE_PASSWORD` — credentials for the source MySQL instance.

### Step 2 — Run the environment setup script

The script validates that all pre-provisioned resources are reachable, resolves
their live identifiers, and exports them as `TF_VAR_*` environment variables.

```bash
source ./scripts/setup.sh
```

Expected output:
```
=== Resolving pre-provisioned AWS infrastructure ===
✔  MySQL RDS resolved: recommender-system-rds.xxxx.us-east-1.rds.amazonaws.com
✔  Subnets resolved: subnet-xxxxxxxx / subnet-yyyyyyyy
✔  Kinesis stream resolved: arn:aws:kinesis:us-east-1:...
✔  Inference Lambda resolved: arn:aws:lambda:us-east-1:...
✔  Terraform variable context applied successfully.
INFO: Scripts bucket does not exist yet — Glue script will be uploaded after 'terraform apply'.
=== Setup completed successfully ===
```

> The Glue script upload is skipped on first run because the scripts S3 bucket
> does not exist until after `terraform apply`. The script will print the exact
> command to upload it manually afterwards.

### Step 3 — Deploy infrastructure with Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

`terraform apply` will provision all three modules in dependency order:
1. **etl** — Glue catalog, JDBC connection, crawler, job, IAM role, S3 buckets.
2. **vector_db** — RDS PostgreSQL instance, subnet group, security group, IAM role.
3. **streaming_inference** — Firehose delivery stream, transformation Lambda,
   CloudWatch log group, IAM roles.

RDS provisioning takes approximately 7 minutes.

### Step 4 — Upload the Glue ETL script

After `terraform apply` completes, upload the PySpark script to the scripts bucket:

```bash
aws s3 cp terraform/assets/glue_job/etl-job.py \
  s3://$(terraform output -raw scripts_bucket_id)/etl-job.py
```

### Step 5 — Run the batch ETL job

```bash
aws glue start-job-run \
  --job-name "$(terraform output -raw scripts_bucket_id | sed 's/-[^-]*-[^-]*-scripts$//')-batch-etl-orchestrator" \
  | jq -r '.JobRunId'
```

> The exact job name is also visible in the AWS Glue console under **ETL Jobs**,
> and follows the pattern `recommender-system-batch-etl-orchestrator`.

Check job status (replace `<JobRunId>` with the value from the previous command):

```bash
aws glue get-job-run \
  --job-name "recommender-system-batch-etl-orchestrator" \
  --run-id <JobRunId> \
  --output text --query "JobRun.JobRunState"
```

Wait for status `SUCCEEDED` (approximately 2–3 minutes). Once complete, the
transformed data will appear in the data lake bucket under
`ratings_ml_training/customerNumber=<N>/` partitions.

---

## Vector Database Setup

After the batch job succeeds and the RDS PostgreSQL instance is running, load the
pre-computed embeddings from the ML artifacts bucket into the vector store.

### Step 6 — Retrieve connection details

```bash
terraform output vector_db_host
terraform output -raw vector_db_master_username
terraform output -raw vector_db_master_password
```

Save the username and password — you will need them in the next steps.

### Step 7 — Substitute the bucket name in the SQL script

```bash
sed -i "s/<ML_ARTIFACTS_BUCKET>/${ML_ARTIFACTS_BUCKET}/g" ../sql/embeddings.sql
```

This replaces the placeholder in both `SELECT aws_s3.table_import_from_s3(...)` calls.

### Step 8 — Connect to the vector database and run the ingestion script

```bash
psql \
  --host=$(terraform output -raw vector_db_host) \
  --username=postgres \
  --password \
  --port=5432
```

Enter the password retrieved in Step 6, then run the script:

```sql
\c postgres;
\i '../sql/embeddings.sql'
```

Verify the tables were created:

```sql
\dt *.*
```

You should see `item_emb` and `user_emb`. Exit with `\q`.

---

## Activating the Streaming Pipeline

### Step 9 — Configure the inference Lambda environment variables

The pre-provisioned `recommender-system-model-inference` Lambda needs to know
how to reach the vector database. In the AWS console:

1. Navigate to **Lambda → recommender-system-model-inference → Configuration →
   Environment variables → Edit**.
2. Set the following variables:
   - `VECTOR_DB_HOST` — value of `terraform output -raw vector_db_host`
   - `VECTOR_DB_USER` — value of `terraform output -raw vector_db_master_username`
   - `VECTOR_DB_PASSWORD` — value of `terraform output -raw vector_db_master_password`
3. Click **Save**.

### Step 10 — Verify the streaming pipeline

The Firehose delivery stream will begin consuming from
`recommender-system-kinesis-data-stream` automatically once deployed.
Verify data is flowing:

```bash
# Tail Firehose delivery logs
aws logs tail /aws/kinesisfirehose/recommender-system-delivery-stream --follow

# Confirm S3 recommendations bucket is receiving partitioned payloads
aws s3 ls s3://$(terraform output -raw recommendations_bucket_id)/ --recursive
```

Partitioned output follows the structure:
```
year=YYYY/month=MM/day=DD/hour=HH/recommender-system-delivery-stream-<id>
```

> The Kinesis Data Stream emits events continuously. Allow approximately 5 minutes
> after setup for the first records to appear in S3 and CloudWatch Logs.

---

## Teardown

```bash
cd terraform
terraform destroy
```

> This does not affect the pre-provisioned resources (MySQL RDS, Kinesis Data Stream,
> inference Lambda, or ML artifacts bucket), which are managed externally.
