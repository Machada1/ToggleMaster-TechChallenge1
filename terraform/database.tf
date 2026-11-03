resource "aws_db_subnet_group" "main" {
  name       = "togglemaster-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "togglemaster-db-subnet-group"
  }
}

resource "random_password" "db" {
  length  = 32
  special = false
}

locals {
  effective_db_password = coalesce(var.db_password, random_password.db.result)
  secret_name           = "togglemaster/rds"
}

resource "aws_secretsmanager_secret" "db" {
  name                    = local.secret_name
  recovery_window_in_days = 0

  tags = {
    Name = "togglemaster-rds-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = local.effective_db_password
    engine   = "postgres"
    database = var.db_name
  })
}

resource "aws_db_instance" "main" {
  identifier              = "togglemaster-postgres"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = var.db_instance_class
  allocated_storage       = var.rds_storage_gb
  storage_type            = "gp3"
  db_name                 = var.db_name
  username                = var.db_username
  password                = local.effective_db_password
  port                    = 5432
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  publicly_accessible     = false
  multi_az                = false
  backup_retention_period = 7
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection
  apply_immediately       = true

  depends_on = [aws_secretsmanager_secret_version.db]
}
