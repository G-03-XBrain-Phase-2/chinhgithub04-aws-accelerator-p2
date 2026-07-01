output "name" {
  value       = aws_ssm_parameter.this.name
  description = "The name of the SSM parameter"
}

output "arn" {
  value       = aws_ssm_parameter.this.arn
  description = "The ARN of the SSM parameter"
}
