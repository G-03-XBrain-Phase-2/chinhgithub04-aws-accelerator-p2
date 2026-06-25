variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "repository_name" {
  type        = string
  description = "Tên định danh của ECR Repository"
}

variable "image_tag_mutability" {
  type        = string
  default     = "MUTABLE"
  description = "Chế độ ghi đè tag của ảnh (MUTABLE hoặc IMMUTABLE)"
}

variable "scan_on_push" {
  type        = bool
  default     = true
  description = "Tự động quét lỗi bảo mật khi push ảnh lên ECR"
}

variable "keep_last_n_images" {
  type        = number
  default     = 10
  description = "Số lượng ảnh tag latest được giữ lại (để tránh tốn phí lưu trữ ECR vô hạn)"
}
