output "ec2_public_ip" {
  value       = aws_instance.k8s_host.public_ip
  description = "IP công cộng của máy ảo EC2 host chạy cụm Kind"
}

output "alb_dns_name" {
  value       = aws_lb.external.dns_name
  description = "Địa chỉ DNS của Application Load Balancer (ALB) truy cập từ Internet"
}

output "app_url" {
  value       = "http://${aws_lb.external.dns_name}"
  description = "Đường dẫn URL để mở nhanh trang web của ứng dụng trên trình duyệt"
}
