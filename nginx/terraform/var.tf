variable "cluster_name" {
  description = "The ECS cluster name"
  default     = "imtech"
}

variable "service_name" {
  description = "The ECS service name"
  default     = "ofir"
}

variable "desired_count" {
  description = "Desired number of running tasks"
  default     = 1
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
  default     = ["subnet-088b7d937a4cd5d85"]
}

variable "security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
  default     = "sg-0ac3749215afde82a"
}

variable "target_group_name" {
  description = "Using existing target group"
  type        = string
  default     = "ofir"
}

variable "lb_name" {
  type    = string
  default = "imtec"
}

variable "container_image" {
  description = "The Docker image to use for the container. This is overridden by Jenkins in CI."
  type        = string
  default     = "314525640319.dkr.ecr.il-central-1.amazonaws.com/ofir/nginx:latest"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "il-central-1"
}
