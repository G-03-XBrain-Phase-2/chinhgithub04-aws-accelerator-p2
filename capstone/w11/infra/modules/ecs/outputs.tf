output "cluster_id" {
  value       = aws_ecs_cluster.this.id
  description = "ID của ECS Cluster"
}

output "cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "Tên của ECS Cluster"
}

output "service_name" {
  value       = aws_ecs_service.this.name
  description = "Tên của ECS Service"
}

output "security_group_id" {
  value       = aws_security_group.ecs_sg.id
  description = "ID của ECS Task Security Group"
}

output "task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "ARN của ECS Task Role (dùng để gán policy thêm nếu cần)"
}
