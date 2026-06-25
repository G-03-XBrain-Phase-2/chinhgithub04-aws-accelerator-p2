output "database_name" {
  value       = aws_glue_catalog_database.this.name
  description = "Tên của Glue Catalog Database đã tạo"
}

output "workgroup_name" {
  value       = aws_athena_workgroup.this.name
  description = "Tên của Athena Workgroup đã tạo"
}

output "workgroup_arn" {
  value       = aws_athena_workgroup.this.arn
  description = "Amazon Resource Name (ARN) của Athena Workgroup"
}
