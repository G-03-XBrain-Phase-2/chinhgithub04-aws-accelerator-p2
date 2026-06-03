variable "bucket_name" {
  type        = string
  description = "Tên duy nhất toàn cầu của AWS S3 Bucket"
}

variable "tags" {
  type        = map(string)
  description = "Thẻ tag phân loại tài nguyên"
  default     = {}
}
