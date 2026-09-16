
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "cs-with-ai-on-premises-rds-db-subnet-group"
  subnet_ids = module.network.private_subnet_ids
}

resource "aws_security_group" "rds_sg" {
  name        = "cs-with-ai-on-premises-rds-sg"
  description = "CS with AI On-Premises RDS Security Group"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [module.network.vpc_cidr_block]
  }
}

resource "aws_rds_cluster_parameter_group" "rds_pg" {
  name        = "cs-with-ai-on-premises-rds-pg"
  family      = "mysql8.0"
  description = "RDS cluster parameter group for CS with AI On-Premises database"

  # Both services run migrations that create functions and triggers, so this is
  # needed when binary logging is on without the SUPER privilege.
  parameter {
    name  = "log_bin_trust_function_creators"
    value = 1
  }

  parameter {
    name  = "sql_require_primary_key"
    value = 0
  }
}

# One database for both services - this is what compatible mode is. They share
# the schema for environments, security and logs, and each keeps its own
# service-specific tables alongside.
resource "aws_rds_cluster" "cluster" {
  cluster_identifier          = "cs-with-ai-on-premises-db"
  engine                      = "mysql"
  engine_version              = local.mysql_engine_version
  master_username             = "root"
  manage_master_user_password = true
  database_name               = "cs_on_premises"
  storage_type                = "io1"
  allocated_storage           = var.mysql.storage
  db_cluster_instance_class   = var.mysql.db_instance
  iops                        = var.mysql.iops

  db_subnet_group_name            = aws_db_subnet_group.db_subnet_group.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.rds_pg.name
  vpc_security_group_ids          = [aws_security_group.rds_sg.id]
  skip_final_snapshot             = true


  storage_encrypted = true

  tags = {
    Name = "cs-with-ai-on-premises-db"
  }

  apply_immediately = true
}

# One Redis for both services, for the same reason.
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "cs-with-ai-on-premises"
  description          = "Redis for CS with AI On-Premises"

  engine               = "redis"
  engine_version       = "7.0"
  parameter_group_name = "default.redis7"
  port                 = 6379

  node_type          = var.redis.node_type
  num_cache_clusters = var.redis.instances

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  preferred_cache_cluster_azs = slice(module.network.availability_zone_names, 0, var.redis.instances <= 3 ? var.redis.instances : 3)
  subnet_group_name           = aws_elasticache_subnet_group.default.name
  security_group_ids          = [aws_security_group.elasticache.id]
}

resource "aws_elasticache_subnet_group" "default" {
  name       = "cs-with-ai-on-premises"
  subnet_ids = module.network.private_subnet_ids
}

resource "aws_security_group" "elasticache" {
  name        = "cs-with-ai-on-premises-redis-sg"
  vpc_id      = module.network.vpc_id
  description = "Handle elasticache database traffic"

  ingress {
    description = "Allow inbound access to the redis default port"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [module.network.vpc_cidr_block]
  }
}
