output "rule_name" {
  value       = aws_cloudwatch_event_rule.this.name
  description = "Tên của EventBridge Rule đã được tạo"
}

output "arn" {
  value       = aws_cloudwatch_event_rule.this.arn
  description = "Amazon Resource Name (ARN) của EventBridge Rule"
}
