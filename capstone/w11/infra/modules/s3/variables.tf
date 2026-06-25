variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "bucket_name" {
  type        = string
  description = "Tên định danh của S3 bucket (sẽ nối thêm project_name làm prefix)"
}

variable "versioning_enabled" {
  type        = bool
  default     = false
  description = "Quyết định có bật Versioning cho S3 Bucket hay không"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Cho phép xóa bucket ngay cả khi còn dữ liệu bên trong (dùng cho môi trường dev/test)"
}

variable "block_public_access" {
  type        = bool
  default     = true
  description = "Quyết định có chặn hoàn toàn truy cập public vào bucket hay không"
}

variable "lifecycle_expiration_days" {
  type        = number
  default     = 0
  description = "Số ngày tự động xóa dữ liệu cũ (chỉ áp dụng nếu giá trị > 0, ví dụ để dọn kết quả Athena)"
}

variable "enable_website" {
  type        = bool
  default     = false
  description = "Quyết định có cấu hình bucket dưới dạng static website hosting hay không"
}
