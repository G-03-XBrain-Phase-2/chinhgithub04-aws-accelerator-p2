output "bucket_arn" {
  value       = aws_s3_bucket.website.arn
  description = "ARN của S3 Bucket vừa khởi tạo"
}

output "website_url" {
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
  description = "Đường dẫn URL truy cập trang web tĩnh"
}
