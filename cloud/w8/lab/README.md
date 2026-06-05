# Kubernetes Platform 1-Click Automation trên AWS EC2 với ALB

Dự án này triển khai tự động hóa hoàn toàn từ cấu hình hạ tầng AWS đến việc thiết lập cụm K8s và deploy ứng dụng web bằng đúng **1 lệnh duy nhất (`terraform apply`)**.

---

## Sơ đồ Kiến trúc Hệ thống (System Architecture)

```text
       [Người dùng truy cập Browser]
                     │
                     ▼ (HTTP Port 80)
         ┌───────────────────────┐
         │     AWS ALB Public    │
         └───────────┬───────────┘
                     │ Forward traffic to Target Group (Port 30080)
                     ▼
  ┌────────────────────────────────────────────────────────┐
  │ VPC (AWS Cloud)                                        │
  │                                                        │
  │  ┌──────────────────────────────────────────────────┐  │
  │  │ EC2 Instance Host (Kind Cluster)                  │  │
  │  │                                                  │  │
  │  │  [Kind Node / Docker Container] (Port 6443 API)   │  │
  │  │   │                                              │  │
  │  │   ├─── [K8s Service NodePort] (Port 30080)       │  │
  │  │   │     │                                        │  │
  │  │   │     ▼                                        │  │
  │  │   └─── [App Pod (Nginx Web)] (Port 80)           │  │
  │  │                                                  │  │
  │  └──────────────────────────────────────────────────┘  │
  └────────────────────────────────────────────────────────┘
```

---

## Giải thích Giải pháp Kỹ thuật & Thiết kế

### 1. Cơ chế liên kết động giữa 2 Provider (Wire Provider)
Để giải quyết bài toán "con gà - quả trứng" khi chưa có cụm K8s nhưng Terraform cần nạp `kubernetes` provider ở bước khởi tạo, dự án sử dụng cơ chế **Dynamic Provider Configuration**:
*   **Bước 1**: AWS Provider dựng VPC, EC2. Một kịch bản SSH Provisioner (`remote-exec`) sẽ cài đặt Docker + Kind và khởi tạo cụm K8s, đồng thời cập nhật IP công cộng của EC2 vào SANs (Subject Alternative Names) của chứng chỉ API Server.
*   **Bước 2**: Một tệp script PowerShell cục bộ (`get_kubeconfig.ps1`) chạy thông qua **`external` data source** sẽ kết nối SSH vào EC2, lấy nội dung tệp `kubeconfig` thô và trích xuất dữ liệu base64 của:
    *   `ca`: Chứng chỉ CA của cụm K8s.
    *   `cert`: Chứng chỉ Client kết nối.
    *   `key`: Khóa bí mật Client.
*   **Bước 3**: Các giá trị này được nạp động vào thuộc tính cấu hình của `kubernetes` provider. Do các giá trị này phụ thuộc vào thuộc tính IP của EC2 (chỉ biết sau khi apply), Terraform sẽ hoãn khởi tạo Kubernetes Provider cho đến khi máy ảo EC2 được dựng xong ở pha apply.

### 2. Cơ chế định tuyến mạng từ ALB vào Pods (NodePort Mapping)
*   **Cấu hình Kind Node**: Cụm Kind được khởi tạo với cấu hình `extraPortMappings` ánh xạ cổng của container node `30080` ra cổng `30080` của máy host EC2.
*   **K8s Service**: Triển khai ứng dụng Web Nginx dưới dạng Service kiểu `NodePort` cố định cổng nhận là `30080`.
*   **AWS ALB**: ALB Target Group có kiểu đích là `instance`, đăng ký máy EC2 làm Target với cổng nhận là `30080`. ALB Listener tiếp nhận lưu lượng HTTP ở cổng `80` từ Internet và chuyển hướng vào Target Group.

---

## Hướng dẫn vận hành nhanh (Quick Start)

### Yêu cầu chuẩn bị
1. Đã cài đặt **Terraform (phiên bản >= 1.5.0)** trên máy local.
2. Đã cấu hình xác thực tài khoản AWS CLI tại máy local có quyền quản trị tài nguyên.

### Lệnh triển khai 1-Click
Thực hiện chạy chuỗi lệnh duy nhất sau tại thư mục này để dựng toàn bộ hệ thống:

```bash
# Khởi tạo providers
terraform init

# Triển khai toàn bộ hạ tầng và ứng dụng (1-click)
terraform apply -auto-approve
```

*Quá trình này mất khoảng 2-3 phút để cài đặt Docker, dựng cụm Kind và nạp cấu hình.*

### Xác minh kết quả
Sau khi lệnh chạy hoàn tất, Terraform sẽ xuất các giá trị đầu ra (Outputs):
1.  **`app_url`**: Sao chép URL này (ví dụ: `http://w8-k8s-lab-alb-123456789.us-east-1.elb.amazonaws.com`) và dán vào trình duyệt để kiểm tra trang web hiển thị thành công.
2.  **`kubeconfig.yaml`**: Terraform tự động tạo ra tệp cấu hình này cục bộ. Bạn có thể sử dụng trực tiếp để tương tác với cụm K8s từ máy cá nhân thông qua lệnh:
    ```bash
    kubectl --kubeconfig=kubeconfig.yaml get pods
    ```

### Dọn dẹp tài nguyên
Sau khi kiểm tra xong, chạy lệnh sau để hủy toàn bộ tài nguyên tránh phát sinh chi phí:

```bash
terraform destroy -auto-approve
```
