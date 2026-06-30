variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "alb_name" {
  type        = string
  description = "Tên định danh cho ALB"
}

variable "internal" {
  type        = bool
  default     = true
  description = "Xác định ALB là internal (true) hay internet-facing (false)"
}

variable "vpc_id" {
  type        = string
  description = "ID của VPC"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Danh sách Subnet IDs để đặt ALB"
}

variable "ingress_rules" {
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  description = "Danh sách các rules cho Ingress của Security Group"
}

variable "target_group_port" {
  type        = number
  default     = 80
  description = "Port của Target Group"
}

variable "target_group_protocol" {
  type        = string
  default     = "HTTP"
  description = "Giao thức của Target Group"
}

variable "target_type" {
  type        = string
  default     = "ip"
  description = "Loại target cho Target Group (ECS Fargate chạy awsvpc nên cần type 'ip')"
}

variable "health_check_path" {
  type        = string
  default     = "/"
  description = "Đường dẫn health check cho Target Group"
}

variable "health_check_port" {
  type        = string
  default     = "traffic-port"
  description = "Port cho health check (mặc định là traffic-port)"
}

variable "health_check_protocol" {
  type        = string
  default     = "HTTP"
  description = "Giao thức cho health check (mặc định là HTTP)"
}

variable "listener_port" {
  type        = number
  default     = 80
  description = "Port cho ALB Listener"
}

variable "listener_protocol" {
  type        = string
  default     = "HTTP"
  description = "Giao thức cho ALB Listener"
}
