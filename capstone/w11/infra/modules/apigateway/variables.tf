variable "name" {
  type        = string
  description = "Tên của API Gateway"
}

variable "description" {
  type        = string
  default     = "HTTP API Gateway for FinOps Watch"
  description = "Mô tả của API Gateway"
}

variable "stage_name" {
  type        = string
  default     = "$default"
  description = "Tên của API stage"
}

variable "lambda_arn" {
  type        = string
  description = "ARN của Lambda function mục tiêu"
}

variable "lambda_function_name" {
  type        = string
  description = "Tên của Lambda function mục tiêu để gán quyền invoke"
}

variable "route_key" {
  type        = string
  default     = "ANY /{proxy+}"
  description = "Route key cho API Gateway (ví dụ: 'POST /slack/actions')"
}

variable "enable_access_logs" {
  type        = bool
  default     = false
  description = "Bật ghi log truy cập (access logs) cho API Gateway"
}

variable "log_group_arn" {
  type        = string
  default     = null
  description = "ARN của CloudWatch Log Group để ghi access logs"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Các tags bổ sung cho tài nguyên"
}
