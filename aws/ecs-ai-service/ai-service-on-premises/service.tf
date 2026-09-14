resource "aws_ecs_service" "service" {
  name            = "ai-service-on-premises"
  cluster         = aws_ecs_cluster.main.arn
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app.instances
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_alb_target_group.app.arn
    container_name   = "ai-service-on-premises"
    container_port   = var.app.port
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }

}

resource "aws_ecs_task_definition" "app" {
  family                   = "ai-service-on-premises"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.app.cpu
  memory                   = var.app.memory
  container_definitions = nonsensitive(jsonencode(
    [
      {
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
            awslogs-group         = aws_cloudwatch_log_group.log_group.name
            awslogs-stream-prefix = "ai-service-on-premises-db-bootstrap"
          }
        }
      },
      {
        name  = "ai-service-on-premises"
        image = "docker.cke-cs.com/ai-service:${var.app.version}"
        repositoryCredentials = {
          credentialsParameter = aws_secretsmanager_secret.docker_token.arn
        }
        portMappings = [
          {
            containerPort = var.app.port
            hostPort      = var.app.port
            protocol      = "tcp"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-region        = var.aws_region
            awslogs-group         = aws_cloudwatch_log_group.log_group.name
            awslogs-stream-prefix = "ai-service-on-premises-logs"
          }
        }
        essential   = true
        healthCheck = null
        dependsOn = [
          {
            containerName = "db-bootstrap",
            condition     = "SUCCESS"
          }
        ]
        environment = concat(
          [
            {
              name  = "APPLICATION_HTTP_PORT",
              value = tostring(var.app.port)
            },
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
            {
              name  = "STORAGE_DRIVER",
              value = "s3"
            },
            {
              name  = "STORAGE_BUCKET",
              value = aws_s3_bucket.storage.id
            },
            {
              name  = "STORAGE_REGION",
              value = var.aws_region
            },
            {
              name  = "ENABLE_METRIC_LOGS",
              value = "true"
            },
            {
              name  = "LOG_LEVEL",
              value = tostring(var.app.log_level)
            },
          ],
          # `MODELS` carries no credentials, only model ids, names and feature
          # lists, so it stays in plain `environment`. Without it the service
          # uses the default model list of every configured provider.
          var.models_config == "" ? [] : [
            {
              name  = "MODELS",
              value = var.models_config
            },
          ]
        )
        secrets = [
          {
            name      = "LICENSE_KEY",
            valueFrom = aws_secretsmanager_secret.license_key.arn
          },
          {
            name      = "ENVIRONMENTS_MANAGEMENT_SECRET_KEY",
            valueFrom = aws_secretsmanager_secret.environments_management_secret_key.arn
          },
          {
            name      = "DATABASE_PASSWORD",
            valueFrom = module.app_db_password.secret_arn
          },
          {
            name      = "PROVIDERS",
            valueFrom = aws_secretsmanager_secret.providers_config.arn
          },
        ]
      }
    ]
  ))
}

resource "aws_iam_role" "task_execution_role" {
  name = "ai-service-on-premises-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "task_execution_role" {
  statement {
    sid     = "AllowAccessToAiServiceOnPremisesSecrets"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.license_key.arn,
      aws_secretsmanager_secret.docker_token.arn,
      aws_secretsmanager_secret.environments_management_secret_key.arn,
      aws_secretsmanager_secret.providers_config.arn,
      module.app_db_password.secret_arn,
      aws_rds_cluster.cluster.master_user_secret[0].secret_arn,
    ]
  }
}

resource "aws_iam_role_policy" "task_execution_role" {
  name = "ai-service-on-premises-secrets"
  role = aws_iam_role.task_execution_role.id

  policy = data.aws_iam_policy_document.task_execution_role.json
}

resource "aws_iam_role" "task_role" {
  name = "ai-service-on-premises-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "task_role" {
  statement {
    sid     = "AllowAccessToS3Bucket"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.storage.arn,
      "${aws_s3_bucket.storage.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "task_role" {
  name = "ai-service-on-premises-s3-access"
  role = aws_iam_role.task_role.id

  policy = data.aws_iam_policy_document.task_role.json
}
