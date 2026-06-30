variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "schedule_name" {
  type        = string
  description = "Tên định danh cho EventBridge Schedule"
}

variable "description" {
  type        = string
  default     = "EventBridge Schedule kích hoạt theo chu kỳ"
  description = "Mô tả chi tiết về schedule"
}

variable "schedule_expression" {
  type        = string
  description = "Biểu thức chu kỳ (cron hoặc rate, ví dụ: cron(0 8 * * ? *) hoặc rate(24 hours))"
}

variable "schedule_expression_timezone" {
  type        = string
  default     = "Asia/Ho_Chi_Minh"
  description = "Múi giờ cho biểu thức cron (mặc định Asia/Ho_Chi_Minh)"
}

variable "is_enabled" {
  type        = bool
  default     = true
  description = "Trạng thái kích hoạt của EventBridge Schedule"
}

variable "flexible_time_window_mode" {
  type        = string
  default     = "OFF"
  description = "Chế độ flexible time window (OFF hoặc FLEXIBLE)"
}

variable "maximum_window_in_minutes" {
  type        = number
  default     = null
  description = "Thời gian tối đa cho flexible window (từ 1 đến 1440). Yêu cầu nếu flexible_time_window_mode là FLEXIBLE"
}

variable "target_arn" {
  type        = string
  description = "ARN của tài nguyên đích cần kích hoạt (ví dụ: Lambda ARN, SQS ARN, Step Functions ARN)"
}

variable "target_input" {
  type        = string
  default     = null
  description = "Dữ liệu đầu vào (JSON string) truyền cho target khi được kích hoạt"
}

variable "create_role" {
  type        = bool
  default     = true
  description = "Quyết định có tạo IAM Role cho Scheduler hay không"
}

variable "role_arn" {
  type        = string
  default     = ""
  description = "ARN của IAM Role đã có sẵn cho Scheduler (chỉ dùng nếu create_role = false)"
}

variable "target_iam_actions" {
  type        = list(string)
  default     = ["lambda:InvokeFunction"]
  description = "Danh sách IAM actions cần cấp cho target (ví dụ: lambda:InvokeFunction, sqs:SendMessage). Chỉ dùng khi create_role = true"
}

variable "retry_policy_maximum_event_age_in_seconds" {
  type        = number
  default     = 86400
  description = "Tuổi thọ tối đa của sự kiện (giây) trước khi bị loại bỏ (từ 60 đến 86400)"
}

variable "retry_policy_maximum_retry_attempts" {
  type        = number
  default     = 185
  description = "Số lần thử lại tối đa khi kích hoạt lỗi (từ 0 đến 185)"
}

