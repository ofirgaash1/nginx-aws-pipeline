#!/bin/bash

cd /workspace/terraform || exit 1

echo "[INFO] Running terraform init..."
terraform init || exit 1

# Check if the ECS service is already in the state
terraform state list | grep '^aws_ecs_service.my_service$' > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "[INFO] ECS service already imported in state. Skipping."
  exit 0
fi


echo "[INFO] Importing ECS service into Terraform state..."
terraform import aws_ecs_service.my_service imtech/ofir || exit 1
echo "[INFO] Importing ALB listener into Terraform state..."
terraform import aws_lb_listener.http arn:aws:elasticloadbalancing:il-central-1:314525640319:listener/app/imtec/dd67eee2877975d6/e8f47476687e464a || exit 1

