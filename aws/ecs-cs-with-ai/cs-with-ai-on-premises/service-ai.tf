resource "aws_ecs_service" "ai" {
  name            = "cs-with-ai-on-premises-ai"
  cluster         = aws_ecs_cluster.main.arn
  task_definition = aws_ecs_task_definition.ai.arn
  desired_count   = var.ai_app.instances
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_alb_target_group.ai.arn
    container_name   = "ai-service-on-premises"
    container_port   = var.ai_app.port
  }

  # Registers the tasks in Cloud Map so the Collaboration Server can resolve
  # them at `local.ai_service_internal_url`.
  service_registries {
    registry_arn = aws_service_discovery_service.ai.arn
  }

  network_configuration {
    security_groups  = [aws_security_group.ai_tasks.id]
    subnets          = module.network.private_subnet_ids
    assign_public_ip = false
  }
}

resource "aws_ecs_task_definition" "ai" {
  family                   = "cs-with-ai-on-premises-ai"
  task_role_arn            = aws_iam_role.task_role.arn
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ai_app.cpu
  memory                   = var.ai_app.memory
  container_definitions = nonsensitive(jsonencode(
    [
      local.db_bootstrap_container,
      {
        name  = "ai-service-on-premises"
        image = "docker.cke-cs.com/ai-service:${var.ai_app.version}"
        repositoryCredentials = {
          credentialsParameter = aws_secretsmanager_secret.ai_docker_token.arn
        }
        portMappings = [
          {
            containerPort = var.ai_app.port
            hostPort      = var.ai_app.port
            protocol      = "tcp"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-region        = var.aws_region
            awslogs-group         = module.logs.log_group_name
            awslogs-stream-prefix = "cs-with-ai-on-premises-ai-logs"
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
              value = tostring(var.ai_app.port)
            },
            # The AI Service keeps its files in the shared SQL database, so
            # compatible mode needs no separate storage for it. Switch to s3 to
            # use the bucket this module already creates - the task role has
            # access to it - or to azure or filesystem.
            {
              name  = "STORAGE_DRIVER",
              value = "database"
            },
            {
              name  = "ENABLE_METRIC_LOGS",
              value = "true"
            },
            {
              name  = "LOG_LEVEL",
              value = tostring(var.ai_app.log_level)
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
        secrets = concat(
          local.shared_data_layer_secrets,
          [
            {
              name      = "LICENSE_KEY",
              valueFrom = aws_secretsmanager_secret.ai_license_key.arn
            },
            {
              name      = "PROVIDERS",
              valueFrom = aws_secretsmanager_secret.providers_config.arn
            },
          ]
        )
      }
    ]
  ))
}
