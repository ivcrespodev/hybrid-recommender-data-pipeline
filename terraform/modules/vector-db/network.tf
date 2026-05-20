# ==============================================================================
# Vector DB Module — Data Sources (Network Discovery)
# ==============================================================================

data "aws_subnet" "public_a" {
  id = var.public_subnet_a_id
}

data "aws_subnet" "public_b" {
  id = var.public_subnet_b_id
}
