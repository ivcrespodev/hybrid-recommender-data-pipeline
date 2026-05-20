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

# Security group: restrict inbound PostgreSQL traffic to the VPC subnets only.
# The instance is publicly accessible so that operators can connect via psql
# from outside the VPC; the security group enforces the actual access boundary.
resource "aws_security_group" "vector_db_sg" {
  name        = "${var.project}-vector-db-sg"
  description = "Allow inbound PostgreSQL traffic from the VPC subnets."
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL access restricted to VPC subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [
      data.aws_subnet.public_a.cidr_block,
      data.aws_subnet.public_b.cidr_block,
    ]
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
# publicly_accessible = true is required so that the psql client can reach the
# instance endpoint directly. Access is controlled by the security group above,
# which limits ingress to the VPC subnet CIDR blocks.
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

  publicly_accessible  = true  # Controlled by security group — see aws_security_group above
  skip_final_snapshot  = true  # Set to false in production to retain point-in-time backups
  db_subnet_group_name = aws_db_subnet_group.vector_db_subnet_group.id

  vpc_security_group_ids = [aws_security_group.vector_db_sg.id]
}
