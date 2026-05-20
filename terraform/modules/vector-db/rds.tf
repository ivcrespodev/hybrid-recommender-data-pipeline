# ==============================================================================
# Vector DB Module — RDS PostgreSQL Instance
# ==============================================================================

# Auto-generate a secure random password for the master database user
resource "random_password" "master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Subnet group spanning two AZs — required by RDS even for single-AZ deployments
resource "aws_db_subnet_group" "vector_db_subnet_group" {
  name        = "${var.project}-vector-db-subnet-group"
  description = "Subnet group for the pgvector RDS instance."

  subnet_ids = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_b.id,
  ]
}

# Security group for the publicly accessible RDS instance.
# Inbound PostgreSQL traffic is open to all IPs so that operators can connect
# directly with psql from any machine (e.g. local workstation or CI runner).
# In production, restrict cidr_blocks to known office/VPN IP ranges.
resource "aws_security_group" "vector_db_sg" {
  name        = "${var.project}-vector-db-sg"
  description = "Allow inbound PostgreSQL traffic from any IP."
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL — open to all IPs for direct psql access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-vector-db-sg"
  }
}

# RDS PostgreSQL instance with pgvector support.
# publicly_accessible = true is required so the RDS endpoint is reachable from
# outside the VPC. Access is gated by the security group defined above.
resource "aws_db_instance" "master_db" {
  identifier            = "${var.project}-vector-db"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"

  engine         = "postgres"
  engine_version = "17.2"
  port           = 5432
  instance_class = "db.t3.micro"

  db_name  = "postgres"
  username = var.master_username
  password = random_password.master_password.result

  publicly_accessible  = true  # Gated by security group above
  skip_final_snapshot  = true  # Set to false in production to retain backups
  db_subnet_group_name = aws_db_subnet_group.vector_db_subnet_group.id

  vpc_security_group_ids = [aws_security_group.vector_db_sg.id]
}
