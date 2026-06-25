variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "database_name" {
  type        = string
  description = "Tên của Glue Catalog Database (chỉ chấp nhận chữ cái, số, và dấu gạch dưới)"
}

variable "workgroup_name" {
  type        = string
  description = "Tên của Athena Workgroup"
}

variable "athena_results_bucket_s3_uri" {
  type        = string
  description = "Đường dẫn S3 URI của bucket lưu kết quả query (ví dụ: s3://my-bucket/results/)"
}

variable "workgroup_force_destroy" {
  type        = bool
  default     = true
  description = "Cho phép xóa Workgroup ngay cả khi còn dữ liệu bên trong"
}
