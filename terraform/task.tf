resource "aws_cloudwatch_log_group" "holidayapp" {
  name = "${var.service_namespace}-holidayapp-${var.environment_id}"
}

resource "aws_ssm_parameter" "otel_endpoint" {
  name  = "/${var.service_namespace}/${var.environment_id}/otel/endpoint"
  type  = "SecureString"
  value = var.otel_exporter_otlp_endpoint
}

resource "aws_ssm_parameter" "otel_headers" {
  name  = "/${var.service_namespace}/${var.environment_id}/otel/headers"
  type  = "SecureString"
  value = var.otel_exporter_otlp_headers
}

resource "aws_iam_role_policy" "task_ssm_policy" {
  name = "${var.service_namespace}-holidayapp-ssm-policy-${var.environment_id}"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          aws_ssm_parameter.otel_endpoint.arn,
          aws_ssm_parameter.otel_headers.arn
        ]
      }
    ]
  })
}

resource "aws_ecs_task_definition" "holidayapp" {
  family             = "${var.service_namespace}-holidayapp-${var.environment_id}"
  memory             = "512"
  cpu                = "256"
  execution_role_arn = aws_iam_role.task_execution.arn # Used by ECS itself before the app starts. Needed to retrieve secrets from SSM.
  # task_role_arn            = aws_iam_role.task_role.arn # Add task role for secrets access
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = "holiday-app"
      image     = aws_ecr_repository.holidayapp.repository_url
      essential = true
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.holidayapp.name,
          "awslogs-region"        = data.aws_region.current.id,
          "awslogs-stream-prefix" = "holidayapp"
        }
      }
      environment = [
        {
          name  = "PORT",
          value = "8080"
        },
        {
          name  = "OTEL_RESOURCE_ATTRIBUTES",
          value = "service.name=holiday-api,service.namespace=holidays,deployment.environment=development"
        },
        {
          name  = "NODE_OPTIONS"
          value = "--require @opentelemetry/auto-instrumentations-node/register" # Essential to bootstrap OpenTelemetry
        },
        {
          name  = "DB_NAME",
          value = aws_db_instance.db.db_name
        },
        {
          name  = "DB_HOST",
          value = aws_db_instance.db.address
        },
        {
          name  = "DB_USER",
          value = aws_db_instance.db.username
        },
      ]
      secrets = [
        {
          name      = "OTEL_EXPORTER_OTLP_ENDPOINT",
          valueFrom = aws_ssm_parameter.otel_endpoint.arn
        },
        {
          name      = "OTEL_EXPORTER_OTLP_HEADERS",
          valueFrom = aws_ssm_parameter.otel_headers.arn
        },
        {
          name      = "DB_PASSWORD",
          valueFrom = aws_ssm_parameter.db_password.arn
        }
      ]
    },
  ])
}

resource "aws_ecs_service" "holidayapp" {
  name            = "${var.service_namespace}-holidayapp"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.holidayapp.arn
  desired_count   = 1 # Simulate multiple instances of this app by setting this to '2'
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnet.default.id]
    security_groups  = [aws_security_group.fargate_task_sg.id]
    assign_public_ip = true
  }

  tags = {
    Name        = "${var.service_namespace}-holidayapp"
    Environment = var.environment_id
    Namespace   = var.service_namespace
  }

}
