# ============================================================================
# Description: External AWS Resource Discovery & Network Context Ingestion
# Purpose: Imports multiple public subnet topologies into the Vector DB context
# Target Architecture: High-Availability (HA) Multi-Subnet Database Allocations
# ============================================================================

# 1. Discover target Primary Availability Zone subnet boundaries
data "aws_subnet" "public_a" {
  id = var.public_subnet_a_id
}

# 2. Discover target Secondary Availability Zone subnet boundaries (Multi-AZ requirement)
data "aws_subnet" "public_b" {
  id = var.public_subnet_b_id
}
