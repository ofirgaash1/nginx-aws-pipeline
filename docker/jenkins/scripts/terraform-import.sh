#!/bin/bash

cd /workspace/terraform || exit 1

echo "[INFO] Running terraform init..."
terraform init -input=false || exit 1

# Check if the ECS service is already in the state
terraform state list | grep '^aws_ecs_service.my_service$' > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "[INFO] ECS service already imported in state. Skipping."
  exit 0
fi

echo "[INFO] Importing ECS service into Terraform state..."
terraform import aws_ecs_service.my_service imtech/ofir || exit 1

