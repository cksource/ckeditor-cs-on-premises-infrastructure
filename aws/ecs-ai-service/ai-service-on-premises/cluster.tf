resource "aws_security_group" "lb" {
  name        = "ai-service-load-balancer-security-group"
  description = "controls access to the ALB"
  vpc_id      = module.network.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "ai-service-ecs-tasks-security-group"
  description = "allow inbound access from the ALB only"
  vpc_id      = module.network.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.app.port
    to_port         = var.app.port
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "main" {
  name                       = "ai-service-load-balancer"
  drop_invalid_header_fields = true
  subnets                    = module.network.public_subnet_ids
  security_groups            = [aws_security_group.lb.id]
}

resource "aws_alb_target_group" "app" {
  name        = "ai-service-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.network.vpc_id
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

resource "aws_alb_listener" "app" {
  load_balancer_arn = aws_alb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "ai-service-on-premises-ecs-cluster"
}
