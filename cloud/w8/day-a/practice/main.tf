resource "tls_private_key" "secure_credentials" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_file" "secure_credential_file" {
  filename        = "${path.module}/secure_credential.pem"
  file_permission = "0600"
  content         = tls_private_key.secure_credentials.private_key_pem

  depends_on = [
    tls_private_key.secure_credentials
  ]
}

resource "local_file" "project_config_metadata" {
  filename        = "${path.module}/project_metadata.json"
  file_permission = "0644"

  content = <<EOF
{
  "project_name": "${var.project_metadata.project_name}",
  "cost_center": ${var.project_metadata.cost_center},
  "tags": ${jsonencode(var.project_metadata.tags)},
  "owner_alias": "${var.developer_credentials["owner_alias"]}",
  "role": "${var.developer_credentials["role"]}",
  "id": "${var.developer_credentials["id"]}",
  "environment": "${var.developer_credentials["environment"]}",
  "enable_security_logs": ${var.enable_security_logs},
  "secret_key_length": ${var.secret_key_length}
}
EOF
}
