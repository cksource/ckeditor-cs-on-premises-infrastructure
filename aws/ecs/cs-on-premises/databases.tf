
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "cs-on-premises-rds-db-subnet-group"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]
}

resource "aws_security_group" "rds_sg" {
  name        = "cs-on-premises-rds-sg"
  description = "CS On-Premises RDS Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
}

resource "aws_rds_cluster_parameter_group" "rds_pg" {
  name        = "cs-on-premises-rds-pg"
  family      = "mysql8.0"
  description = "RDS cluster parameter group for CS On-Premises database"

  parameter {
    name  = "log_bin_trust_function_creators"
    value = 1
  }

  parameter {
    name  = "sql_require_primary_key"
    value = 0
  }
}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier        = "cs-on-premises-db"
  engine                    = "mysql"
  engine_version            = "8.0.35"
  master_username           = "root"
  master_password           = random_string.database_password.result
  database_name             = "cs_on_premises"
  storage_type              = "io1"
  allocated_storage         = var.mysql.storage
  db_cluster_instance_class = var.mysql.db_instance
  iops                      = var.mysql.iops

  db_subnet_group_name            = aws_db_subnet_group.db_subnet_group.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.rds_pg.name
  vpc_security_group_ids          = [aws_security_group.rds_sg.id]
  skip_final_snapshot             = true


  storage_encrypted = true

  tags = {
    Name = "cs-on-premises-db"
  }

  apply_immediately = true
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "cs-on-premises"
  description          = "Redis for CS On-Premises"

  engine               = "redis"
  engine_version       = "7.0"
  parameter_group_name = "default.redis7"
  port                 = 6379

  node_type          = var.redis.node_type
  num_cache_clusters = var.redis.instances

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  preferred_cache_cluster_azs = slice(data.aws_availability_zones.available.names, 0, var.redis.instances <= 3 ? var.redis.instances : 3)
  subnet_group_name           = aws_elasticache_subnet_group.default.name
  security_group_ids          = [aws_security_group.elasticache.id]
}

resource "aws_elasticache_subnet_group" "default" {
  name       = "cs-on-premises"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_security_group" "elasticache" {
  name        = "cs-on-premises-redis-sg"
  vpc_id      = aws_vpc.vpc.id
  description = "Handle elasticache database traffic"

  ingress {
    description = "Allow inbound access to the redis default port"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
}
