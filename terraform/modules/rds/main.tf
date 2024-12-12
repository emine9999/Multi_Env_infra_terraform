
resource "aws_db_subnet_group" "main" {
  count       = length(var.environment)
  name        = "db-subnet-group-${var.environment[0]}"
  subnet_ids  = var.db_subnet_ids
  description = "DB subnet group for ${var.environment[0]}"
}

# Security group for RDS
resource "aws_security_group" "rds" {
  count  = length(var.environment)
  name   = "rds-sg-${var.environment[0]}"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]  # Allow access from EKS
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  count = length(var.environment)

  identifier = "rds-${var.environment[0]}"
  engine     = "postgres"
  engine_version = "13.7"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp2"

  username = "dbadmin"
  password = var.db_password  # Should be handled securely through secrets management

  db_subnet_group_name   = aws_db_subnet_group.main[count.index].name
  vpc_security_group_ids = [aws_security_group.rds[count.index].id]

  # Different configurations based on environment
  multi_az = var.environment[0] != "dev"  # true for staging and prod, false for dev
  
  # Backups
  backup_retention_period = var.environment[0] == "dev" ? 7 : 30
  backup_window          = "03:00-04:00"
  
  # Maintenance
  maintenance_window = "Mon:04:00-Mon:05:00"

  # Enhanced monitoring
  monitoring_interval = var.environment[0] == "dev" ? 0 : 60
  monitoring_role_arn = var.environment[0] == "dev" ? null : aws_iam_role.rds_monitoring[0].arn

  tags = {
    Name        = "rds-${var.environment[0]}"
    Environment = var.environment[0]
  }
}

# IAM role for enhanced monitoring (only for staging/prod)
resource "aws_iam_role" "rds_monitoring" {
  count = var.environment[0] == "dev" ? 0 : 1
  name  = "rds-monitoring-role-${var.environment[0]}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.environment[0] == "dev" ? 0 : 1
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}