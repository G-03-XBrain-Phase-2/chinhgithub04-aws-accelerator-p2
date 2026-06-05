variable "aws_region" {
  type        = string
  description = "Vùng AWS triển khai tài nguyên"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "Loại máy ảo EC2 dùng làm Host chạy cụm Kind"
  default     = "t3.medium"
}

variable "project_name" {
  type        = string
  description = "Tên của dự án/lab"
  default     = "w8-k8s-lab"
}

variable "tags" {
  type        = map(string)
  description = "Các thẻ tag chung để gắn lên tài nguyên AWS"
  default = {
    Environment = "lab"
    Owner       = "XB-DN26-080"
    Project     = "W8-K8s-ALB-Automation"
    ManagedBy   = "Terraform"
  }
}
