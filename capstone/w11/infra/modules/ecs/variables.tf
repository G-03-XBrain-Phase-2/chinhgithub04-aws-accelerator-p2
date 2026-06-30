variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "service_name" {
  type        = string
  description = "Tên định danh cho ECS Service"
}

variable "vpc_id" {
  type        = string
  description = "ID của VPC"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Danh sách Subnet IDs chạy ECS tasks (nên dùng private subnets)"
}

variable "alb_security_group_id" {
  type        = string
  description = "ID của ALB Security Group để cho phép traffic đi vào ECS Task"
}

variable "container_image" {
  type        = string
  description = "URI của Container Image trên ECR hoặc Docker Hub"
}

variable "container_port" {
  type        = number
  default     = 8080
  description = "Port mà ứng dụng bên trong container lắng nghe"
}

variable "cpu" {
  type        = number
  default     = 256
  description = "Số lượng CPU cho Fargate Task (ví dụ: 256 = 0.25 vCPU)"
}

variable "memory" {
  type        = number
  default     = 512
  description = "Bộ nhớ cho Fargate Task tính bằng MB (ví dụ: 512)"
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Số lượng Fargate tasks mong muốn chạy đồng thời"
}

variable "target_group_arn" {
  type        = string
  description = "ARN của Target Group trên ALB để gắn vào ECS Service"
}

variable "log_retention_in_days" {
  type        = number
  default     = 14
  description = "Số ngày lưu trữ logs cho CloudWatch Log Group của ECS Task"
}

variable "environment_variables" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "Danh sách biến môi trường truyền cho Container"
}
