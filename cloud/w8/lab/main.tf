# ==========================================
# 1. MẠNG VÀ CƠ SỞ HẠ TẦNG (NETWORK)
# ==========================================

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# 2. KHÓA SSH TỰ ĐỘNG TẠO (DYNAMIC SSH KEY)
# ==========================================

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0600"
}

# ==========================================
# 3. TƯỜNG LỬA BẢO MẬT (SECURITY GROUPS)
# ==========================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Cho phep truy cap HTTP vao ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-alb"
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-sg-ec2"
  description = "Cho phep SSH, K8s API va NodePort tu ALB"
  vpc_id      = aws_vpc.main.id

  # Cho phép SSH để Terraform provisioning
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Cho phép kết nối trực tiếp K8s API từ local máy người chạy
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Chỉ cho phép ALB kết nối đến cổng NodePort 30080
  ingress {
    from_port       = 30080
    to_port         = 30080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-ec2"
  }
}

# ==========================================
# 4. MÁY MÁY ẢO CHỦ (EC2 INSTANCE)
# ==========================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "k8s_host" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-ec2-host"
  }
}

# ==========================================
# 5. TỰ ĐỘNG HÓA PROVISION CỤM K8S (SSH EXEC)
# ==========================================

resource "null_resource" "k8s_setup" {
  depends_on = [aws_instance.k8s_host, local_file.private_key]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh_key.private_key_pem
    host        = aws_instance.k8s_host.public_ip
    timeout     = "5m"
  }

  # Upload script cài đặt lên máy ảo
  provisioner "file" {
    source      = "${path.module}/scripts/install_kind.sh"
    destination = "/home/ubuntu/install_kind.sh"
  }

  # Cấp quyền và thực thi script với quyền root và truyền IP công cộng làm tham số
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/install_kind.sh",
      "sudo /home/ubuntu/install_kind.sh ${aws_instance.k8s_host.public_ip}"
    ]
  }
}

# ==========================================
# 6. TRÍCH XUẤT CHỨNG CHỈ (EXTERNAL DATA)
# ==========================================

data "external" "kubeconfig" {
  depends_on = [null_resource.k8s_setup]

  program = ["powershell", "-ExecutionPolicy", "Bypass", "-File", "${path.module}/scripts/get_kubeconfig.ps1"]

  query = {
    ip       = aws_instance.k8s_host.public_ip
    key_path = local_file.private_key.filename
  }
}

# Tạo file kubeconfig.yaml cục bộ để lập trình viên dùng nhanh sau đó
resource "local_file" "kubeconfig" {
  depends_on = [data.external.kubeconfig]
  content    = <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${data.external.kubeconfig.result.ca}
    server: https://${aws_instance.k8s_host.public_ip}:6443
  name: kind-kind
contexts:
- context:
    cluster: kind-kind
    user: kind-kind
  name: kind-kind
current-context: kind-kind
kind: Config
preferences: {}
users:
- name: kind-kind
  user:
    client-certificate-data: ${data.external.kubeconfig.result.cert}
    client-key-data: ${data.external.kubeconfig.result.key}
EOF
  filename   = "${path.module}/kubeconfig.yaml"
}
