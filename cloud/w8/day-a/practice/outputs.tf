output "secure_credential_file_path" {
  description = "Đường dẫn tuyệt đối của tệp khóa bảo mật (.pem) trên máy local"
  value       = abspath(local_file.secure_credential_file.filename)
}

output "project_config_metadata_file_path" {
  description = "Đường dẫn tuyệt đối của tệp JSON chứa siêu dữ liệu dự án"
  value       = abspath(local_file.project_config_metadata.filename)
}

output "public_key_openssh" {
  description = "Nội dung khóa công khai định dạng OpenSSH được sinh ra ở runtime"
  value       = tls_private_key.secure_credentials.public_key_openssh
}
