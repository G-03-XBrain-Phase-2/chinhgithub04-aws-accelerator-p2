output "schedule_name" {
  value       = aws_scheduler_schedule.this.name
  description = "Tên của EventBridge Schedule đã được tạo"
}

output "arn" {
  value       = aws_scheduler_schedule.this.arn
  description = "Amazon Resource Name (ARN) của EventBridge Schedule"
}

output "role_arn" {
  value       = var.create_role ? aws_iam_role.scheduler[0].arn : var.role_arn
  description = "ARN của IAM Role được sử dụng bởi Schedule"
}
