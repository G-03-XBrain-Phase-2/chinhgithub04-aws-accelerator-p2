#!/bin/bash
set -e
set -x

echo "=== STARTING KUBERNETES KIND PLATFORM INSTALLATION ==="

# Hàm chờ giải phóng khóa apt/dpkg tránh xung đột khi vừa boot máy ảo
wait_for_apt() {
  echo "Waiting for apt/dpkg locks to release..."
  while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "Apt is currently locked by another process. Waiting 5s..."
    sleep 5
  done
  echo "Apt locks released."
}

# Chờ cloud-init hoàn thành
echo "Waiting for cloud-init to complete..."
sudo cloud-init status --wait || true

# 1. Cập nhật hệ thống
wait_for_apt
sudo apt-get update -y

# 2. Cài đặt các thư viện cần thiết
wait_for_apt
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. Thêm Docker GPG key và repository
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Cài đặt Docker
wait_for_apt
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 5. Cấu hình Docker Service
sudo systemctl start docker || true
sudo systemctl enable docker || true

# Chờ docker socket sẵn sàng
echo "Waiting for Docker socket to be ready..."
for i in {1..30}; do
  if [ -S /var/run/docker.sock ]; then
    echo "Docker socket is ready."
    break
  fi
  sleep 2
done

# Cấp quyền docker socket cho user ubuntu
sudo usermod -aG docker ubuntu
sudo chmod 666 /var/run/docker.sock

# 6. Cài đặt kubectl
echo "Installing kubectl..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# 7. Cài đặt Kind
echo "Installing Kind..."
KIND_VERSION="v0.22.0"
curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64"
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# 8. Lấy IP công cộng của EC2 (Ưu tiên tham số truyền vào từ Terraform)
PUBLIC_IP=$1
if [ -z "$PUBLIC_IP" ]; then
  PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || curl -s https://ifconfig.me || echo "")
fi
echo "EC2 Public IP is: ${PUBLIC_IP}"

# 9. Tạo tệp cấu hình cho Kind Cluster
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "0.0.0.0"
  apiServerPort: 6443
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    listenAddress: "0.0.0.0"
    protocol: TCP
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      certSANs:
      - "localhost"
      - "127.0.0.1"
      - "${PUBLIC_IP}"
EOF

# 10. Khởi chạy cụm Kind (Chạy trực tiếp dưới quyền root để đảm bảo quyền ghi chép)
echo "Checking if Kind cluster already exists..."
if kind get clusters | grep -q "^kind$"; then
  echo "Cluster 'kind' already exists. Deleting it for a clean installation..."
  kind delete cluster --name kind
fi

echo "Creating Kind cluster..."
kind create cluster --config kind-config.yaml

# 11. Thiết lập thư mục và tệp kubeconfig cho user ubuntu
echo "Configuring kubeconfig for ubuntu user..."
mkdir -p /home/ubuntu/.kube
cp /root/.kube/config /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# 12. Thay đổi địa chỉ máy chủ API trong kubeconfig thành IP công cộng của EC2
sed -i "s/server: https:\/\/127.0.0.1:6443/server: https:\/\/${PUBLIC_IP}:6443/g" /home/ubuntu/.kube/config

echo "=== KUBERNETES KIND PLATFORM INSTALLATION COMPLETED SUCCESSFULLY ==="
