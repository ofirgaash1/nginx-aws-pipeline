provider "aws" {
    region = "il-central-1"
}

data "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/ofir-log"
}

data "aws_lb_target_group" "existing_tg" {
  name = var.target_group_name
}

data "aws_lb" "existing_alb" {
  name = var.lb_name
}



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
        "awslogs-group" = data.aws_cloudwatch_log_group.ecs_log_group.name

        "awslogs-region"        = "il-central-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }  
  }])
}

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

# Outputs (to display relevant information after deployment)
output "ecs_service_name" {
  value = aws_ecs_service.my_service.name
}
output "task_definition_arn" {
  value = aws_ecs_task_definition.my_task_definition.arn
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.existing_alb.arn
  port              = 8085
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.existing_tg.arn
  }
}
