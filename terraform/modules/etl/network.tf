# ============================================================================
# Description: External AWS Resource Discovery & Data Fetching Manifest
# Purpose: Imports existing target network and security contexts into Glue ETL
# ============================================================================

# 1. Discover operational network boundary topologies for JDBC connectivity
data "aws_subnet" "public_a" {
  id = var.public_subnet_a_id
}

# 2. Discover existing database security boundary ingress/egress state
data "aws_security_group" "db_sg" {
  id = var.db_sg_id
}
