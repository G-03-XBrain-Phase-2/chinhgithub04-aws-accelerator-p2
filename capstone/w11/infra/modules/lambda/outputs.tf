output "function_name" {
  value       = aws_lambda_function.this.function_name
  description = "Tên của Lambda function đã khởi tạo"
}

output "arn" {
  value       = aws_lambda_function.this.arn
  description = "Amazon Resource Name (ARN) của Lambda function"
}

output "role_name" {
  value       = aws_iam_role.lambda_role.name
  description = "Tên của IAM Execution Role"
}

output "role_arn" {
  value       = aws_iam_role.lambda_role.arn
  description = "ARN của IAM Execution Role"
}

output "function_url" {
  value       = var.create_function_url ? aws_lambda_function_url.this[0].function_url : ""
  description = "Public URL của Lambda function (nếu create_function_url được bật)"
}
