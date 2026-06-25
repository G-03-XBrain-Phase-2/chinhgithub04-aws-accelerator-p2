variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "topic_name" {
  type        = string
  description = "Tên của SNS Topic"
}

variable "kms_master_key_id" {
  type        = string
  default     = "alias/aws/sns"
  description = "ID hoặc Alias của KMS Key dùng để mã hóa tin nhắn trong topic (mặc định alias/aws/sns)"
}

variable "subscriptions" {
  type = map(object({
    protocol = string
    endpoint = string
  }))
  default     = {}
  description = "Bản đồ cấu hình subscriptions nhận tin nhắn (Key là tên định danh, protocol: email/sms/lambda/https, endpoint: địa chỉ đích)"
}
