# ==============================================================================
# ETL Module — Data Sources (Network & Security Discovery)
# ==============================================================================

# Discover the subnet used to attach Glue ENIs for JDBC connectivity
data "aws_subnet" "public_a" {
  id = var.public_subnet_a_id
}

# Discover the security group attached to the source MySQL instance
data "aws_security_group" "db_sg" {
  id = var.db_sg_id
}
