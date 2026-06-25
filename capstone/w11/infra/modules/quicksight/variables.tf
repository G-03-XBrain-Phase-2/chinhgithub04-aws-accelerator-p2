variable "project_name" {
  type        = string
  description = "Tên của dự án (ví dụ: finops-watch)"
}

variable "athena_workgroup_name" {
  type        = string
  description = "Tên của Athena Workgroup dùng để truy vấn dữ liệu"
}
