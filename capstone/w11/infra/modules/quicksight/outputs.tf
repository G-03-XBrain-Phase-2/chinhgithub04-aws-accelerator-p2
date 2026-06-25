output "data_source_arn" {
  value       = aws_quicksight_data_source.athena.arn
  description = "Amazon Resource Name (ARN) của QuickSight Athena Data Source"
}

output "data_source_id" {
  value       = aws_quicksight_data_source.athena.data_source_id
  description = "ID của QuickSight Athena Data Source"
}
