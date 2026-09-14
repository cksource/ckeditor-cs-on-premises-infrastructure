resource "aws_ecs_service" "cs" {
  name            = "cs-with-ai-on-premises-cs"
  cluster         = aws_ecs_cluster.main.arn
  task_definition = aws_ecs_task_definition.cs.arn
  desired_count   = var.cs_app.instances
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_alb_target_group.cs.arn
    container_name   = "cs-on-premises"
    container_port   = var.cs_app.port
  }

  network_configuration {
    security_groups  = [aws_security_group.cs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }
}

resource "aws_ecs_task_definition" "cs" {
  family                   = "cs-with-ai-on-premises-cs"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cs_app.cpu
  memory                   = var.cs_app.memory
  container_definitions = nonsensitive(jsonencode(
    [
      local.db_bootstrap_container,
      {
        name  = "cs-on-premises"
        image = "docker.cke-cs.com/cs:${var.cs_app.version}"
        repositoryCredentials = {
          credentialsParameter = aws_secretsmanager_secret.cs_docker_token.arn
        }
        portMappings = [
          {
            containerPort = var.cs_app.port
            hostPort      = var.cs_app.port
            protocol      = "tcp"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-region        = var.aws_region
            awslogs-group         = aws_cloudwatch_log_group.log_group.name
            awslogs-stream-prefix = "cs-with-ai-on-premises-cs-logs"
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
          local.shared_data_layer_environment,
          [
            {
              name  = "APPLICATION_HTTP_PORT",
              value = tostring(var.cs_app.port)
            },
            # Where the management panel reaches the AI API. It defaults to the
            # Collaboration Server's own port, which is only correct when both
            # services run inside one process - here they are two ECS services,
            # so it has to point at the AI Service.
            {
              name  = "AI_API_BASE_URL",
              value = local.ai_service_internal_url
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
              value = tostring(var.cs_app.log_level)
            },
          ]
        )
        secrets = concat(
          local.shared_data_layer_secrets,
          [
            {
              name      = "LICENSE_KEY",
              valueFrom = aws_secretsmanager_secret.cs_license_key.arn
            },
          ]
        )
      }
    ]
  ))
}
