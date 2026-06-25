variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "table_name" {
  type        = string
  description = "Tên định danh của bảng DynamoDB (sẽ nối thêm project_name làm prefix)"
}

variable "hash_key" {
  type        = string
  description = "Tên của Partition Key (Hash Key)"
}

variable "hash_key_type" {
  type        = string
  default     = "S"
  description = "Kiểu dữ liệu của Partition Key (S, N, hoặc B)"
}

variable "range_key" {
  type        = string
  default     = null
  description = "Tên của Sort Key (Range Key) - Tùy chọn"
}

variable "range_key_type" {
  type        = string
  default     = null
  description = "Kiểu dữ liệu của Sort Key (S, N, hoặc B) - Tùy chọn"
}

variable "billing_mode" {
  type        = string
  default     = "PAY_PER_REQUEST"
  description = "Chế độ tính phí của DynamoDB (mặc định PAY_PER_REQUEST/On-demand để tối ưu chi phí)"
}

variable "ttl_enabled" {
  type        = bool
  default     = false
  description = "Quyết định có bật tính năng Time To Live (TTL) để tự động xóa log hay không"
}

variable "ttl_attribute" {
  type        = string
  default     = "ttl"
  description = "Tên trường dùng làm mốc thời gian TTL"
}
