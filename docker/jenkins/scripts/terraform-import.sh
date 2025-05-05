#!/bin/bash

IMPORT_FLAG_FILE="/workspace/terraform/.terraform-imported"

cd /workspace/terraform || exit 1

if [ -f "$IMPORT_FLAG_FILE" ]; then
  echo "[INFO] Terraform import already completed. Skipping."
  exit 0
fi

echo "[INFO] Running terraform init..."
terraform init || exit 1

echo "[INFO] Importing ECS service into Terraform state..."
terraform import aws_ecs_service.my_service imtech/ofir || exit 1

# Mark as completed
touch "$IMPORT_FLAG_FILE"
echo "[INFO] Import completed. Flag written to $IMPORT_FLAG_FILE"
