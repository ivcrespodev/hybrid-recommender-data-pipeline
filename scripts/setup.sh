#!/bin/bash
set -e

# 1. Check if the secure local configuration file (.env) exists
SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
if [ ! -f "${SCRIPT_DIR}/../.env" ]; then
    echo "ERROR: The .env file was not found in the root directory."
    echo "Please copy .env.example to .env and populate your real credentials."
    exit 1
fi

# 2. Load local secret environment variables into the current session
export $(cat "${SCRIPT_DIR}/../.env" | xargs)

# 3. Global project naming configuration (Enterprise-grade naming convention)
export PROJECT_PREFIX="recommender-system"
export AWS_DEFAULT_REGION="us-east-1"

echo "=== Ingesting and discovering AWS Infrastructure state ==="

# 4. Fetch dynamic networking identifiers from AWS using the enterprise identifier
export VPC_ID=$(aws rds describe-db-instances --db-instance-identifier "${PROJECT_PREFIX}-rds" --output text --query "DBInstances[].DBSubnetGroup.VpcId" 2>/dev/null || echo "vpc-mock-id")

# 5. Export Terraform variables dynamically for the active shell session (TF_VAR_ prefix)
export TF_VAR_project="${PROJECT_PREFIX}"
export TF_VAR_region="${AWS_DEFAULT_REGION}"
export TF_VAR_vpc_id="${VPC_ID}"

## Networking subnets (Standard Enterprise tag architecture)
export TF_VAR_private_subnet_a_id=$(aws ec2 describe-subnets --filters "Name=tag:Environment,Values=Production" "Name=tag:Type,Values=PrivateA" "Name=vpc-id,Values=${VPC_ID}" --output text --query "Subnets[].SubnetId")
export TF_VAR_public_subnet_a_id=$(aws ec2 describe-subnets --filters "Name=tag:Environment,Values=Production" "Name=tag:Type,Values=PublicA" "Name=vpc-id,Values=${VPC_ID}" --output text --query "Subnets[].SubnetId")
export TF_VAR_public_subnet_b_id=$(aws ec2 describe-subnets --filters "Name=tag:Environment,Values=Production" "Name=tag:Type,Values=PublicB" "Name=vpc-id,Values=${VPC_ID}" --output text --query "Subnets[].SubnetId")

## Database credentials parsed directly from your local secure .env file
export TF_VAR_db_sg_id=$(aws rds describe-db-instances --db-instance-identifier "${PROJECT_PREFIX}-rds" --output text --query "DBInstances[].VpcSecurityGroups[].VpcSecurityGroupId")
export TF_VAR_source_host=$(aws rds describe-db-instances --db-instance-identifier "${PROJECT_PREFIX}-rds" --output text --query "DBInstances[].Endpoint.Address")
export TF_VAR_source_port=3306
export TF_VAR_source_database="classicmodels"
export TF_VAR_source_username="${VECTOR_DB_USER}"
export TF_VAR_source_password="${VECTOR_DB_PASSWORD}"

## Streaming Inference & Serverless triggers
export TF_VAR_kinesis_stream_arn=$(aws kinesis describe-stream --stream-name "${PROJECT_PREFIX}-kinesis-data-stream" --output text --query "StreamDescription.StreamARN")
export TF_VAR_inference_api_url=$(aws lambda get-function-url-config --function-name "${PROJECT_PREFIX-model-inference}" --output text --query "FunctionUrl")

## S3 Bucket naming policies generated dynamically with enterprise prefix
export TF_VAR_data_lake_bucket="${PROJECT_PREFIX}-${AWS_ACCOUNT_ID}-${AWS_DEFAULT_REGION}-datalake"
export TF_VAR_scripts_bucket="${PROJECT_PREFIX}-${AWS_ACCOUNT_ID}-${AWS_DEFAULT_REGION-scripts}"
export TF_VAR_recommendations_bucket="${PROJECT_PREFIX}-${AWS_ACCOUNT_ID}-${AWS_DEFAULT_REGION}-recommendations"

echo "✔ Environment mappings applied successfully to Terraform context."

# 6. Synchronize core ETL application code to the scripts storage bucket
GLUE_SCRIPT_PATH="${SCRIPT_DIR}/../terraform/assets/glue_job/etl-job.py"
if [ -f "${GLUE_SCRIPT_PATH}" ]; then
    echo "Synchronizing Glue ETL deployment packages to S3..."
    aws s3 cp "${GLUE_SCRIPT_PATH}" "s3://${TF_VAR_scripts_bucket}/etl-job.py"
else
    echo "WARNING: Local etl-job.py not found at ${GLUE_SCRIPT_PATH}. Skipping S3 sync."
fi

echo "=== Setup execution completed successfully ==="