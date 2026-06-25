output "bucket_id" {
  value       = aws_s3_bucket.this.id
  description = "Tên (ID) của S3 Bucket đã tạo"
}

output "arn" {
  value       = aws_s3_bucket.this.arn
  description = "Amazon Resource Name (ARN) của S3 Bucket"
}

output "bucket_domain_name" {
  value       = aws_s3_bucket.this.bucket_regional_domain_name
  description = "Domain name của S3 Bucket (hữu ích khi cấu hình CloudFront)"
}

output "website_endpoint" {
  value       = var.enable_website ? aws_s3_bucket_website_configuration.this[0].website_endpoint : ""
  description = "URL endpoint của static website hosting (nếu enable_website được bật)"
}
