output "vpc_id" {
  value       = aws_vpc.this.id
  description = "ID của VPC"
}

output "public_subnet_ids" {
  value       = { for k, v in aws_subnet.public : k => v.id }
  description = "Bản đồ ID của các Public Subnets"
}

output "private_subnet_ids" {
  value       = { for k, v in aws_subnet.private : k => v.id }
  description = "Bản đồ ID của các Private Subnets"
}

output "database_subnet_ids" {
  value       = { for k, v in aws_subnet.database : k => v.id }
  description = "Bản đồ ID của các Database Subnets"
}

output "private_route_table_ids" {
  value       = { for k, v in aws_route_table.private : k => v.id }
  description = "Bản đồ ID của các Private Route Tables"
}

output "database_route_table_ids" {
  value       = { for k, v in aws_route_table.database : k => v.id }
  description = "Bản đồ ID của các Database Route Tables"
}
