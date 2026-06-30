output "alb_id" {
  value       = aws_lb.this.id
  description = "ID của ALB"
}

output "alb_arn" {
  value       = aws_lb.this.arn
  description = "ARN của ALB"
}

output "alb_dns_name" {
  value       = aws_lb.this.dns_name
  description = "Tên miền (DNS) của ALB"
}

output "target_group_arn" {
  value       = aws_lb_target_group.this.arn
  description = "ARN của Target Group mặc định"
}

output "listener_arn" {
  value       = aws_lb_listener.http.arn
  description = "ARN của Listener mặc định"
}

output "security_group_id" {
  value       = aws_security_group.alb_sg.id
  description = "ID của Security Group đang gán cho ALB"
}
