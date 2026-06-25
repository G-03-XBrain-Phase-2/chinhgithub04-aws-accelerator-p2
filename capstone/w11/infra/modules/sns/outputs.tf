output "topic_arn" {
  value       = aws_sns_topic.this.arn
  description = "Amazon Resource Name (ARN) của SNS Topic"
}

output "topic_name" {
  value       = aws_sns_topic.this.name
  description = "Tên của SNS Topic đã tạo"
}
