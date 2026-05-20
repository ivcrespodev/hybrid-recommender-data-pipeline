# ==============================================================================
# Terraform Core Configuration
# Backend: Local state storage (suitable for development and single-operator use)
# Note:    State files are excluded from version control via .gitignore
#
# To migrate to a remote backend for team environments, replace the local block
# with the S3 configuration below:
#
#   backend "s3" {
#     bucket         = "recommender-system-global-infrastructure-state"
#     key            = "environments/production/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "infrastructure-state-locking-table"
#     encrypt        = true
#   }
# ==============================================================================

terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  required_version = ">= 1.5.0"
}
