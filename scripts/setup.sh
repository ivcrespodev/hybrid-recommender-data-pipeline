#!/bin/bash
# ==============================================================================
# Setup Script — Hybrid Recommender Data Pipeline
# Purpose: Loads .env credentials, resolves identifiers from pre-provisioned AWS
#          resources, and exports all required TF_VAR_ variables for the active
#          shell session. Also uploads the Glue ETL script to the scripts bucket.
#
# Usage:   source ./scripts/setup.sh   (must be sourced, not executed)
#
# Pre-provisioned resources required before running this script:
#   - RDS MySQL instance:    recommender-system-rds
#   - Kinesis Data Stream:   recommender-system-kinesis-data-stream
#   - Lambda function:       recommender-system-model-inference
#   - VPC with two public subnets tagged:
#       Environment=Production / Type=PublicA
#       Environment=Production / Type=PublicB
# ==============================================================================
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Locate and validate the local .env configuration file
# ------------------------------------------------------------------------------
SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
ENV_FILE="${SCRIPT_DIR}/../.env"

if [ ! -f "${ENV_FILE}" ]; then
    echo "ERROR: '.env' file not found at ${ENV_FILE}"
    echo "       Run: cp .env.example .env — then populate it with your values."
    return 1
fi

# ------------------------------------------------------------------------------
# 2. Load environment variables from .env
# ------------------------------------------------------------------------------
set -o allexport
# shellcheck source=/dev/null
source "${ENV_FILE}"
set +o allexport

# ------------------------------------------------------------------------------
# 3. Static project-level configuration
# ------------------------------------------------------------------------------
export PROJECT_PREFIX="recommender-system"
export AWS_DEFAULT_REGION="${AWS_REGION:-us-east-1}"

echo "=== Resolving pre-provisioned AWS infrastructure ==="

# ------------------------------------------------------------------------------
# 4. Resolve VPC and networking identifiers from the pre-provisioned MySQL RDS
# ------------------------------------------------------------------------------
MYSQL_INSTANCE="${PROJECT_PREFIX}-rds"

if ! aws rds describe-db-instances \
        --db-instance-identifier "${MYSQL_INSTANCE}" \
        --output text --query "DBInstances[].DBInstanceIdentifier" \
        > /dev/null 2>&1; then
    echo "ERROR: Pre-provisioned RDS instance '${MYSQL_INSTANCE}' not found."
    echo "       Ensure the source MySQL database is running before executing this script."
    return 1
fi

export VPC_ID
VPC_ID=$(aws rds describe-db-instances \
    --db-instance-identifier "${MYSQL_INSTANCE}" \
    --output text \
    --query "DBInstances[].DBSubnetGroup.VpcId")

export TF_VAR_db_sg_id
TF_VAR_db_sg_id=$(aws rds describe-db-instances \
    --db-instance-identifier "${MYSQL_INSTANCE}" \
    --output text \
    --query "DBInstances[].VpcSecurityGroups[].VpcSecurityGroupId")

export TF_VAR_source_host
TF_VAR_source_host=$(aws rds describe-db-instances \
    --db-instance-identifier "${MYSQL_INSTANCE}" \
    --output text \
    --query "DBInstances[].Endpoint.Address")

echo "✔  MySQL RDS resolved: ${TF_VAR_source_host}"

# ------------------------------------------------------------------------------
# 5. Resolve subnet identifiers (tagged in the pre-provisioned VPC)
# ------------------------------------------------------------------------------
export TF_VAR_public_subnet_a_id
TF_VAR_public_subnet_a_id=$(aws ec2 describe-subnets \
    --filters \
        "Name=tag:Environment,Values=Production" \
        "Name=tag:Type,Values=PublicA" \
        "Name=vpc-id,Values=${VPC_ID}" \
    --output text \
    --query "Subnets[].SubnetId")

export TF_VAR_public_subnet_b_id
TF_VAR_public_subnet_b_id=$(aws ec2 describe-subnets \
    --filters \
        "Name=tag:Environment,Values=Production" \
        "Name=tag:Type,Values=PublicB" \
        "Name=vpc-id,Values=${VPC_ID}" \
    --output text \
    --query "Subnets[].SubnetId")

echo "✔  Subnets resolved: ${TF_VAR_public_subnet_a_id} / ${TF_VAR_public_subnet_b_id}"

# ------------------------------------------------------------------------------
# 6. Resolve Kinesis Data Stream ARN (pre-provisioned)
# ------------------------------------------------------------------------------
KINESIS_STREAM="${PROJECT_PREFIX}-kinesis-data-stream"

if ! aws kinesis describe-stream \
        --stream-name "${KINESIS_STREAM}" \
        --output text --query "StreamDescription.StreamName" \
        > /dev/null 2>&1; then
    echo "ERROR: Pre-provisioned Kinesis stream '${KINESIS_STREAM}' not found."
    echo "       Ensure the Kinesis Data Stream is active before executing this script."
    return 1
fi

export TF_VAR_kinesis_stream_arn
TF_VAR_kinesis_stream_arn=$(aws kinesis describe-stream \
    --stream-name "${KINESIS_STREAM}" \
    --output text \
    --query "StreamDescription.StreamARN")

echo "✔  Kinesis stream resolved: ${TF_VAR_kinesis_stream_arn}"

# ------------------------------------------------------------------------------
# 7. Resolve inference Lambda ARN (pre-provisioned)
#    Uses get-function instead of get-function-url-config, which requires a
#    Function URL to be configured and would fail if one is not present.
# ------------------------------------------------------------------------------
INFERENCE_LAMBDA="${PROJECT_PREFIX}-model-inference"

if ! aws lambda get-function \
        --function-name "${INFERENCE_LAMBDA}" \
        --output text --query "Configuration.FunctionName" \
        > /dev/null 2>&1; then
    echo "ERROR: Pre-provisioned Lambda function '${INFERENCE_LAMBDA}' not found."
    echo "       Ensure the inference Lambda is deployed before executing this script."
    return 1
fi

export TF_VAR_inference_api_url
TF_VAR_inference_api_url=$(aws lambda get-function \
    --function-name "${INFERENCE_LAMBDA}" \
    --output text \
    --query "Configuration.FunctionArn")

echo "✔  Inference Lambda resolved: ${TF_VAR_inference_api_url}"

# ------------------------------------------------------------------------------
# 8. Export all remaining Terraform input variables
# ------------------------------------------------------------------------------
export TF_VAR_project="${PROJECT_PREFIX}"
export TF_VAR_region="${AWS_DEFAULT_REGION}"
export TF_VAR_vpc_id="${VPC_ID}"

export TF_VAR_source_port="3306"
export TF_VAR_source_database="classicmodels"
export TF_VAR_source_username="${DB_SOURCE_USER}"
export TF_VAR_source_password="${DB_SOURCE_PASSWORD}"

export TF_VAR_ml_artifacts_bucket="${ML_ARTIFACTS_BUCKET}"
export TF_VAR_data_lake_bucket="${PROJECT_PREFIX}-${AWS_ACCOUNT_ID}-${AWS_DEFAULT_REGION}-datalake"
export TF_VAR_scripts_bucket="${PROJECT_PREFIX}-${AWS_ACCOUNT_ID}-${AWS_DEFAULT_REGION}-scripts"
export TF_VAR_recommendations_bucket="${PROJECT_PREFIX}-${AWS_ACCOUNT_ID}-${AWS_DEFAULT_REGION}-recommendations"

echo "✔  Terraform variable context applied successfully."

# ------------------------------------------------------------------------------
# 9. Upload the Glue ETL script to the S3 scripts bucket
#    The scripts bucket is created by Terraform, so this step runs after apply.
#    If the bucket does not exist yet, the upload is skipped gracefully.
# ------------------------------------------------------------------------------
GLUE_SCRIPT_PATH="${SCRIPT_DIR}/../terraform/assets/glue_job/etl-job.py"

if aws s3 ls "s3://${TF_VAR_scripts_bucket}" > /dev/null 2>&1; then
    echo "Uploading Glue ETL script to s3://${TF_VAR_scripts_bucket}/etl-job.py ..."
    aws s3 cp "${GLUE_SCRIPT_PATH}" "s3://${TF_VAR_scripts_bucket}/etl-job.py"
    echo "✔  Glue script uploaded."
else
    echo "INFO: Scripts bucket does not exist yet — Glue script will be uploaded after 'terraform apply'."
    echo "      Re-run: aws s3 cp ${GLUE_SCRIPT_PATH} s3://${TF_VAR_scripts_bucket}/etl-job.py"
fi

echo "=== Setup completed successfully ==="
