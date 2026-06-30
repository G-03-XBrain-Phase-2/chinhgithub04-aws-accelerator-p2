variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "queue_name" {
  type        = string
  description = "Tên định danh cho SQS Queue"
}

variable "fifo_queue" {
  type        = bool
  default     = false
  description = "Định dạng hàng đợi là FIFO hay Standard"
}

variable "visibility_timeout_seconds" {
  type        = number
  default     = 30
  description = "Thời gian message bị ẩn sau khi consumer lấy (giây)"
}

variable "message_retention_seconds" {
  type        = number
  default     = 345600
  description = "Thời gian tối đa message tồn tại trong hàng đợi (giây)"
}

variable "delay_seconds" {
  type        = number
  default     = 0
  description = "Thời gian delay trước khi message có thể tiêu thụ (giây)"
}

variable "max_message_size" {
  type        = number
  default     = 262144
  description = "Kích thước message tối đa (bytes)"
}

variable "receive_wait_time_seconds" {
  type        = number
  default     = 0
  description = "Thời gian polling tối đa (giây) - Long Polling"
}

variable "create_dlq" {
  type        = bool
  default     = false
  description = "Có tạo Dead Letter Queue hay không"
}

variable "max_receive_count" {
  type        = number
  default     = 5
  description = "Số lần nhận tin nhắn thất bại tối đa trước khi đưa vào DLQ"
}
