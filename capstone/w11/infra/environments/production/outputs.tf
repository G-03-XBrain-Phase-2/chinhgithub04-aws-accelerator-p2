output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID của VPC được tạo"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Bản đồ ID của các Public Subnets"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Bản đồ ID của các Private Subnets"
}

output "database_subnet_ids" {
  value       = module.vpc.database_subnet_ids
  description = "Bản đồ ID của các Database Subnets"
}

output "ecr_repository_url" {
  value       = module.ai_engine_ecr.repository_url
  description = "URL của ECR Repository vừa tạo"
}

output "slack_interactive_api_endpoint" {
  value       = "${module.slack_interactive_api.api_endpoint}/slack/actions"
  description = "URL cấu hình Request URL trong Interactivity của Slack App"
}

