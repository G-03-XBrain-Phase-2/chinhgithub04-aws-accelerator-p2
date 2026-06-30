output "queue_id" {
  value       = aws_sqs_queue.this.id
  description = "URL của SQS Queue"
}

output "queue_arn" {
  value       = aws_sqs_queue.this.arn
  description = "ARN của SQS Queue"
}

output "queue_name" {
  value       = aws_sqs_queue.this.name
  description = "Tên của SQS Queue"
}

output "dlq_id" {
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].id : null
  description = "URL của DLQ"
}

output "dlq_arn" {
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].arn : null
  description = "ARN của DLQ"
}
