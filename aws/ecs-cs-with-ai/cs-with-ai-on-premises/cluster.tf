resource "aws_security_group" "lb" {
  name        = "cs-with-ai-load-balancer-security-group"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Collaboration Server"
    protocol    = "tcp"
    from_port   = local.cs_listener_port
    to_port     = local.cs_listener_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "CKEditor AI Service"
    protocol    = "tcp"
    from_port   = local.ai_listener_port
    to_port     = local.ai_listener_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cs_tasks" {
  name        = "cs-with-ai-cs-tasks-security-group"
  description = "allow inbound access to the Collaboration Server from the ALB only"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = var.cs_app.port
    to_port         = var.cs_app.port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ai_tasks" {
  name        = "cs-with-ai-ai-tasks-security-group"
  description = "allow inbound access to the AI Service from the ALB and from the Collaboration Server"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "Browser traffic through the load balancer"
    protocol        = "tcp"
    from_port       = var.ai_app.port
    to_port         = var.ai_app.port
    security_groups = [aws_security_group.lb.id]
  }

  ingress {
    description     = "AI API calls proxied by the Collaboration Server management panel"
    protocol        = "tcp"
    from_port       = var.ai_app.port
    to_port         = var.ai_app.port
    security_groups = [aws_security_group.cs_tasks.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "main" {
  name                       = "cs-with-ai-load-balancer"
  drop_invalid_header_fields = true
  subnets                    = aws_subnet.public.*.id
  security_groups            = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "cs" {
  name        = "cs-with-ai-cs-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "60"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/health"
    unhealthy_threshold = "3"
  }
}

resource "aws_alb_target_group" "ai" {
  name        = "cs-with-ai-ai-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "60"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/health"
    unhealthy_threshold = "3"
  }
}

resource "aws_alb_listener" "cs" {
  load_balancer_arn = aws_alb.main.id
  port              = local.cs_listener_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.cs.id
    type             = "forward"
  }
}

resource "aws_alb_listener" "ai" {
  load_balancer_arn = aws_alb.main.id
  port              = local.ai_listener_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ai.id
    type             = "forward"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "cs-with-ai-on-premises-ecs-cluster"
}

# Private DNS for service-to-service traffic. The Collaboration Server
# management panel proxies AI API calls, and resolving the AI Service here keeps
# that traffic inside the VPC instead of going back out through the public load
# balancer.
resource "aws_service_discovery_private_dns_namespace" "internal" {
  name        = local.internal_namespace
  description = "Internal service discovery for CS with AI On-Premises"
  vpc         = aws_vpc.vpc.id
}

resource "aws_service_discovery_service" "ai" {
  name = local.ai_service_dns_name

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  # ECS manages registration and deregistration of the task IPs itself.
  health_check_custom_config {}
}
