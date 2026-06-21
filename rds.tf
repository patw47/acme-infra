# ── CLEAN BASELINE ──────────────────────────────────────────────────────────

# CLEAN: encrypted, private RDS — the correct baseline
resource "aws_db_instance" "acme_secure_rds" {
  identifier        = "${var.environment}-acme-secure-db"
  engine            = "postgres"
  engine_version    = "14"
  instance_class    = "db.t4g.large"
  allocated_storage = 20

  db_name  = var.pg_db_name
  username = var.pg_username
  password = var.pg_password
  port     = var.pg_port

  storage_encrypted   = true
  publicly_accessible = false

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.app_security_group.security_group_id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 7

  skip_final_snapshot = true

  tags = local.tags
}

# ── TRUE RED FLAGS ───────────────────────────────────────────────────────────

# RED FLAG: publicly accessible RDS
resource "aws_db_instance" "acme_public_rds" {
  identifier        = "${var.environment}-acme-public-db"
  engine            = "postgres"
  engine_version    = "14"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.pg_db_name
  username = var.pg_username
  password = var.pg_password
  port     = var.pg_port

  storage_encrypted   = true
  publicly_accessible = true

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.app_security_group.security_group_id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 7

  skip_final_snapshot = true

  tags = local.tags
}

# RED FLAG: storage not encrypted
resource "aws_db_instance" "acme_unencrypted_rds" {
  identifier        = "${var.environment}-acme-unencrypted-db"
  engine            = "postgres"
  engine_version    = "14"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.pg_db_name
  username = var.pg_username
  password = var.pg_password
  port     = var.pg_port

  storage_encrypted   = false
  publicly_accessible = false

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.app_security_group.security_group_id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 0

  skip_final_snapshot = true

  tags = local.tags
}
