# Cluster, définition de tâche et service ECS Fargate

# Cluster sans instance EC2 (équivalent du type "Networking only" de la console)
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${var.project}-cluster" }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project}-api"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = "${var.project}-api"
    image     = "${aws_ecr_repository.api.repository_url}:${var.api_image_tag}"
    essential = true

    portMappings = [{
      containerPort = var.api_port
      protocol      = "tcp"
    }]

    environment = [
      { name = "DB_HOST", value = aws_db_instance.main.address },
      { name = "DB_USER", value = aws_db_instance.main.username },
      { name = "DB_NAME", value = aws_db_instance.main.db_name },
      # RDS impose TLS (rds.force_ssl = 1) ; pg lit PGSSLMODE, ce qui évite de modifier index.js
      { name = "PGSSLMODE", value = "no-verify" }
    ]

    # Mot de passe lu dans Secrets Manager au démarrage du conteneur
    secrets = [{
      name      = "DB_PASSWORD"
      valueFrom = "${aws_db_instance.main.master_user_secret[0].secret_arn}:password::"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.api.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "api"
      }
    }
  }])

  tags = { Name = "${var.project}-api-task" }
}

resource "aws_ecs_service" "api" {
  name            = "${var.project}-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "${var.project}-api"
    container_port   = var.api_port
  }

  health_check_grace_period_seconds = 60

  # Retour automatique à la version précédente si un déploiement échoue
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # terraform apply attend que les tâches soient saines derrière l'ALB
  wait_for_steady_state = true

  depends_on = [aws_lb_listener.http, aws_iam_role_policy_attachment.ecs_execution]

  tags = { Name = "${var.project}-api-service" }
}
