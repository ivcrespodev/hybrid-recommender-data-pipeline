# ============================================================================
# Description: Multi-AZ Relational Database Service (RDS) Engine
# Engine: PostgreSQL (Equipped with pgvector spatial search extension)
# Tier: High-Availability Storage Core Layer
# ============================================================================

# 1. Cryptographic high-entropy credential generator for the database admin account
resource "random_password" "master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 2. Network topology subnet grouping mapping high-availability boundaries
resource "aws_db_subnet_group" "vector_db_subnet_group" {
  name        = "${var.project}-vector-db-subnet-group"
  description = "Isolated network boundary allocation grouping public multi-AZ subnets for cluster communication."
  
  subnet_ids = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_b.id
  ]
}

# 3. Secure network boundary group restricting network ingress traffic
resource "aws_security_group" "vector_db_sg" {
  name        = "${var.project}-vector-db-security-boundary"
  description = "Ingress/Egress security boundary matrix restricting administrative and application access to the vector store."
  vpc_id      = var.vpc_id

  # Ingress restricted exclusively to the localized internal network topologies
  ingress {
    description = "Isolated communication port routing for internal vector queries"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_subnet.public_a.cidr_block, data.aws_subnet.public_b.cidr_block]
  }

  egress {
    description = "Allow seamless outbound updates and handshake requests"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-vector-db-sg"
  }
}

# 4. Relational Database Instance (Target Vector Analytical Core)
resource "aws_db_instance" "master_db" {
  identifier            = "${var.project}-vector-db-node"
  allocated_storage     = 20
  max_allocated_storage = 0
  storage_type          = "gp2"
  engine                = "postgres"
  engine_version        = "17.2"
  port                  = 5432
  instance_class        = "db.t3.micro"
  
  db_name               = "postgres"
  username              = var.master_username
  password              = random_password.master_password.result
  
  # Structural enterprise configurations
  publicly_accessible    = true # Accessible through routing proxies if required
  skip_final_snapshot    = true # Set to false in production environments
  db_subnet_group_name   = aws_db_subnet_group.vector_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.vector_db_sg.id]
}
