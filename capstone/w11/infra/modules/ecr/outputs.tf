output "repository_name" {
  value       = aws_ecr_repository.this.name
  description = "Tên của ECR Repository đã tạo"
}

output "repository_url" {
  value       = aws_ecr_repository.this.repository_url
  description = "URL của ECR Repository (dùng để login và push docker image)"
}

output "arn" {
  value       = aws_ecr_repository.this.arn
  description = "Amazon Resource Name (ARN) của ECR Repository"
}
