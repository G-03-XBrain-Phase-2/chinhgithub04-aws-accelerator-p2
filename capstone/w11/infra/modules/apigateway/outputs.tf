output "api_id" {
  value       = aws_apigatewayv2_api.this.id
  description = "ID của API Gateway"
}

output "api_endpoint" {
  value       = aws_apigatewayv2_api.this.api_endpoint
  description = "Endpoint URI của API Gateway"
}

output "execution_arn" {
  value       = aws_apigatewayv2_api.this.execution_arn
  description = "Execution ARN của API Gateway"
}

output "stage_id" {
  value       = aws_apigatewayv2_stage.this.id
  description = "ID của API Gateway Stage"
}
