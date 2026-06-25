variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "rule_name" {
  type        = string
  description = "Tên định danh cho EventBridge Rule"
}

variable "description" {
  type        = string
  default     = "EventBridge Rule kích hoạt theo chu kỳ"
  description = "Mô tả chi tiết về rule"
}

variable "schedule_expression" {
  type        = string
  description = "Biểu thức chu kỳ (cron hoặc rate, ví dụ: cron(0 8 * * ? *) hoặc rate(24 hours))"
}

variable "target_arn" {
  type        = string
  description = "ARN của tài nguyên đích cần kích hoạt (ví dụ: Lambda ARN)"
}

variable "lambda_function_name" {
  type        = string
  default     = ""
  description = "Tên của Lambda function đích (chỉ điền nếu tài nguyên đích là Lambda, dùng để tự động tạo permission)"
}

variable "is_enabled" {
  type        = bool
  default     = true
  description = "Trạng thái kích hoạt của EventBridge Rule"
}
