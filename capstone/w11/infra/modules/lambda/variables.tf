variable "function_name" {
  type        = string
  description = "Tên của AWS Lambda function"
}

variable "description" {
  type        = string
  default     = "Lambda function phục vụ hệ thống FinOps Watch"
  description = "Mô tả chức năng của Lambda"
}

variable "handler" {
  type        = string
  description = "Điểm khởi chạy (entry point) của Lambda function (ví dụ: index.handler)"
}

variable "runtime" {
  type        = string
  default     = "python3.9"
  description = "Môi trường thực thi (runtime) của Lambda function"
}

variable "timeout" {
  type        = number
  default     = 30
  description = "Thời gian thực thi tối đa của Lambda (giây)"
}

variable "memory_size" {
  type        = number
  default     = 128
  description = "Dung lượng RAM cấp phát cho Lambda (MB)"
}

variable "source_dir" {
  type        = string
  description = "Đường dẫn thư mục cục bộ chứa mã nguồn của Lambda để tự động nén ZIP"
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Bản đồ các biến môi trường cấu hình cho Lambda"
}

variable "iam_policy_document_json" {
  type        = string
  default     = ""
  description = "Chuỗi JSON định nghĩa IAM Policy custom gán riêng cho Execution Role của Lambda này"
}

variable "create_function_url" {
  type        = bool
  default     = false
  description = "Quyết định có tạo Public Function URL cho Lambda này hay không (dùng để expose API)"
}

variable "log_retention_in_days" {
  type        = number
  default     = 14
  description = "Số ngày lưu trữ logs trong CloudWatch Log Group để tối ưu chi phí FinOps"
}

variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}
