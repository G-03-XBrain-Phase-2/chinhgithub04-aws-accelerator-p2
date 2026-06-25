output "table_name" {
  value       = aws_dynamodb_table.this.name
  description = "Tên của bảng DynamoDB đã khởi tạo"
}

output "arn" {
  value       = aws_dynamodb_table.this.arn
  description = "Amazon Resource Name (ARN) của bảng DynamoDB"
}
