variable "aws_region" {
  type        = string
  description = "Khu vực AWS triển khai tài nguyên"
}

variable "project_name" {
  type        = string
  description = "Tên dự án phát triển"
}

variable "bucket_name" {
  type        = string
  description = "Tên duy nhất toàn cầu của S3 Bucket dùng cho trang web tĩnh"
}

variable "tags" {
  type = object({
    Environment = string
    Owner       = string
    Project     = string
  })
  description = "Các thẻ tag chung áp dụng cho mọi tài nguyên của môi trường"
}
