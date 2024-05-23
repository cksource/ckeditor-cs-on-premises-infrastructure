resource "aws_ecs_service" "service" {
  name            = "cs-on-premises"
  cluster         = aws_ecs_cluster.main.arn
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_alb_target_group.app.arn
    container_name   = "cs-on-premises"
    container_port   = var.app.port
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }

}

resource "aws_ecs_task_definition" "app" {
  family                   = "cs-on-premises"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.app.cpu
  memory                   = var.app.memory
  container_definitions = jsonencode(
    [
      {
        name  = "cs-on-premises"
        image = "docker.cke-cs.com/cs:${var.app.version}"
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
            awslogs-stream-prefix = "cs-on-premises-logs"
          }
        }
        essential   = true
        healthCheck = null
        environment = [
          {
            name  = "REDIS_HOST",
            value = aws_elasticache_replication_group.redis.primary_endpoint_address
          },
          {
            name  = "DATABASE_HOST",
            value = aws_rds_cluster.cluster.endpoint
          },
          {
            name  = "DATABASE_USER",
            value = aws_rds_cluster.cluster.master_username
          },
          {
            name  = "DATABASE_DATABASE",
            value = aws_rds_cluster.cluster.database_name
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
            name  = "COLLABORATION_STORAGE_DRIVER",
            value = "s3"
          },
          {
            name  = "COLLABORATION_STORAGE_BUCKET",
            value = aws_s3_bucket.storage.id
          },
          {
            name  = "COLLABORATION_STORAGE_REGION",
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
        ]
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
            valueFrom = aws_secretsmanager_secret.database_password.arn
          },
        ]
      }
    ]
  )
}

resource "aws_iam_role" "task_execution_role" {
  name = "cs-on-premises-task-execution"

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
    sid     = "AllowAccessToCsOnPremisesSecrets"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.license_key.arn,
      aws_secretsmanager_secret.docker_token.arn,
      aws_secretsmanager_secret.environments_management_secret_key.arn,
      aws_secretsmanager_secret.database_password.arn
    ]
  }
}

resource "aws_iam_role_policy" "task_execution_role" {
  name = "cs-on-premises-secrets"
  role = aws_iam_role.task_execution_role.id

  policy = data.aws_iam_policy_document.task_execution_role.json
}

resource "aws_iam_role" "task_role" {
  name = "cs-on-premises-task"

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
  name = "cs-on-premises-s3-access"
  role = aws_iam_role.task_role.id

  policy = data.aws_iam_policy_document.task_role.json
}
