locals {
  # Both applications connect to the shared database as this one user. In
  # compatible mode they share the schema, so a single application user holding
  # the privileges both services need is enough.
  app_db_username = "cs_app"

  mysql_engine_version = "8.0.46"

  # The AI Service is reached over Cloud Map from inside the VPC, so the
  # Collaboration Server management panel can proxy AI API calls without
  # hairpinning through the public load balancer.
  internal_namespace  = "cs-with-ai.internal"
  ai_service_dns_name = "ai-service"

  ai_service_internal_url = "http://${local.ai_service_dns_name}.${local.internal_namespace}:${var.ai_app.port}"

  # Both applications serve HTTP and browsers need to reach both, so one load
  # balancer carries them on two ports rather than needing two DNS names for
  # host-based routing. Path-based routing is deliberately avoided: the two
  # services do not have disjoint URL prefixes.
  cs_listener_port = 80
  ai_listener_port = 8080

  # This is what compatible mode comes down to: identical database and Redis
  # settings on both sides. The AI Service detects the Collaboration Server
  # through the shared data layer by itself - there is no flag that turns the
  # integration on, so these values drifting apart is the one thing that breaks
  # it. They are defined once here and spliced into both task definitions.
  shared_data_layer_environment = [
    {
      name  = "DATABASE_DRIVER",
      value = "mysql"
    },
    {
      name  = "DATABASE_HOST",
      value = aws_rds_cluster.cluster.endpoint
    },
    {
      name  = "DATABASE_USER",
      value = local.app_db_username
    },
    {
      name  = "DATABASE_DATABASE",
      value = aws_rds_cluster.cluster.database_name
    },
    {
      name  = "REDIS_HOST",
      value = aws_elasticache_replication_group.redis.primary_endpoint_address
    },
  ]

  shared_data_layer_secrets = [
    {
      name      = "DATABASE_PASSWORD",
      valueFrom = module.app_db_password.secret_arn
    },
    # Both services are configured from the same management panel, so they take
    # the same panel password.
    {
      name      = "ENVIRONMENTS_MANAGEMENT_SECRET_KEY",
      valueFrom = aws_secretsmanager_secret.environments_management_secret_key.arn
    },
  ]

  # Creates the shared application database user. It is attached to both task
  # definitions rather than only one, because ECS cannot order one service's
  # start-up against another's - whichever task comes up first has to be able to
  # bootstrap. The SQL is idempotent, so running it repeatedly is harmless.
  db_bootstrap_container = {
    name       = "db-bootstrap"
    image      = "public.ecr.aws/docker/library/mysql:${local.mysql_engine_version}"
    essential  = false
    entryPoint = ["sh", "-c"]
    command = [
      <<-EOT
      mysql -h "$DATABASE_HOST" -u "$DATABASE_ADMIN_USER" <<SQL
      ALTER DATABASE ${aws_rds_cluster.cluster.database_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
      CREATE USER IF NOT EXISTS '${local.app_db_username}'@'%' IDENTIFIED BY '$APP_DB_PASSWORD';
      GRANT SELECT, INSERT, UPDATE, DELETE, ALTER, CREATE, DROP, INDEX, TRIGGER, LOCK TABLES, REFERENCES ON ${aws_rds_cluster.cluster.database_name}.* TO '${local.app_db_username}'@'%';
      FLUSH PRIVILEGES;
      SQL
      EOT
    ]
    environment = [
      {
        name  = "DATABASE_HOST",
        value = aws_rds_cluster.cluster.endpoint
      },
      {
        name  = "DATABASE_ADMIN_USER",
        value = aws_rds_cluster.cluster.master_username
      },
    ]
    secrets = [
      {
        name      = "MYSQL_PWD",
        valueFrom = "${aws_rds_cluster.cluster.master_user_secret[0].secret_arn}:password::"
      },
      {
        name      = "APP_DB_PASSWORD",
        valueFrom = module.app_db_password.secret_arn
      },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-region        = var.aws_region
        awslogs-group         = module.logs.log_group_name
        awslogs-stream-prefix = "cs-with-ai-on-premises-db-bootstrap"
      }
    }
  }
}
