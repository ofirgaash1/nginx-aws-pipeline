provider "aws" {
  region = "il-central-1"
}

# === Data sources ===
data "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/ofir-logs"
}

data "aws_lb_target_group" "existing_tg" {
  name = var.target_group_name
}

data "aws_lb" "existing_alb" {
  name = var.lb_name
}

# === IAM role for Lambda ===
resource "aws_iam_role" "lambda_exec" {
  name = "ofir-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_dynamo_logs" {
  name = "lambda-dynamo-logs"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:il-central-1:314525640319:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:il-central-1:314525640319:log-group:/aws/lambda/ofir-dynamo:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Scan"
        ]
        Resource = "arn:aws:dynamodb:il-central-1:314525640319:table/imtech"
      }
    ]
  })
}

# === Lambda function ===
resource "aws_lambda_function" "ofir_lambda" {
  function_name    = "ofir-dynamo"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "ofir_lambda.lambda_handler"
  runtime          = "python3.12"
  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
}

# === ECS task definition ===
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "ofir-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::314525640319:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([{
    name      = "nginx-ofir-container"
    image     = var.container_image
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = data.aws_cloudwatch_log_group.ecs_log_group.name
        "awslogs-region"        = "il-central-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# === ECS service ===
resource "aws_ecs_service" "my_service" {
  name            = var.service_name
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = data.aws_lb_target_group.existing_tg.arn
    container_name   = "nginx-ofir-container"
    container_port   = 80
  }
}

# === ALB Listener ===
resource "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.existing_alb.arn
  port              = 8085
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.existing_tg.arn
  }
}

# === API Gateway ===
resource "aws_api_gateway_rest_api" "api" {
  name = "ofir-api"
}

resource "aws_api_gateway_resource" "ofir_lambda_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "ofir-lambda"
}

resource "aws_api_gateway_method" "any" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.ofir_lambda_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.ofir_lambda_resource.id
  http_method             = aws_api_gateway_method.any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.ofir_lambda.invoke_arn
}

# === CORS support (OPTIONS method) ===
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.ofir_lambda_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_mock" {
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.ofir_lambda_resource.id
  http_method       = "OPTIONS"
  type              = "MOCK"
  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.ofir_lambda_resource.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.ofir_lambda_resource.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }

  response_templates = {
    "application/json" = ""
  }
}

# === API Deployment ===
resource "aws_api_gateway_deployment" "api_deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "default"

  depends_on = [
    aws_api_gateway_integration.lambda_proxy
  ]
}

# === Outputs ===
output "ecs_service_name" {
  value = aws_ecs_service.my_service.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.my_task_definition.arn
}

output "api_gateway_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/default/ofir-lambda"
}
