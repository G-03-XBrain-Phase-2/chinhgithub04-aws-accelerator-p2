variable "project_metadata" {
  type = object({
    project_name = string
    cost_center  = number
    tags         = list(string)
  })
  description = "Thông tin định danh và thẻ phân loại của dự án"
  default = {
    project_name = "aws-accelerator-p2"
    cost_center  = 4092026
    tags         = ["cloud", "devops", "W8-D1"]
  }
}

variable "developer_credentials" {
  type        = map(string)
  description = "Thông tin cấu hình tài khoản nhà phát triển hệ thống"
  default = {
    owner_alias = "chinhgithub04"
    role        = "CloudDevOpsEngineer"
    id          = "XB-DN26-080"
    environment = "staging-lab"
  }
}

variable "secret_key_length" {
  type        = number
  description = "Độ dài ký tự của khóa bảo mật được sinh ngẫu nhiên"
  default     = 32
}

variable "enable_security_logs" {
  type        = bool
  description = "Bật hoặc tắt chức năng ghi log bảo mật"
  default     = true
}
