# W8-D2: Nhật ký Tự học — Kiến trúc Kubernetes & Cài đặt Môi trường

Tài liệu này lưu trữ toàn bộ nội dung nghiên cứu lý thuyết và hướng dẫn cấu hình cụm Kubernetes cục bộ trong Ngày 2 (Tuần 8).

---

## Cấu trúc thư mục mô-đun

```text
cloud/w8/day-b/
├── theory/
│   ├── 01_k8s_architecture.md   # Phân tích Control Plane, Worker Node & Container Runtime
│   ├── 02_k8s_resources.md      # Khái niệm Pod, Service (ClusterIP, NodePort, LoadBalancer) & Probes
│   └── 03_k8s_config_network.md # Giải pháp ConfigMap/Secret & NetworkPolicy
├── setup/
│   └── local_environment.md     # Hướng dẫn cài đặt & kiểm tra Docker, minikube, kubectl
├── manifests/
│   ├── 01_configmap.yaml        # Định nghĩa các biến cấu hình không nhạy cảm
│   ├── 02_secret.yaml.example   # Bản mẫu cấu hình thông tin mật mã nhạy cảm 
│   ├── 03_deployment.yaml       # Cấu hình Deployment quản lý vòng đời ứng dụng (tự phục hồi & scale)
│   ├── 04_service.yaml          # Service kiểu NodePort để expose ứng dụng
│   └── 05_networkpolicy.yaml    # Chính sách tường lửa mạng bảo vệ Pod
└── README.md                    # Trang mục lục điều hướng
```

---

## Điểm nhấn của các phân khu

### [1. Lý thuyết](theory/)
Khu vực lưu trữ các ghi chép chi tiết về các thành phần cốt lõi của hệ điều hành đám mây:
- **[Chuyên đề 01: Kiến trúc tổng quan Kubernetes](theory/01_k8s_architecture.md)**: Tìm hiểu vai trò của Control Plane, cơ chế làm việc của etcd, bộ lập lịch scheduler, tác nhân kubelet trên Worker Node và luồng khởi tạo Pod chi tiết.
- **[Chuyên đề 02: Các tài nguyên cốt lõi trong Kubernetes](theory/02_k8s_resources.md)**: Nghiên cứu bản chất dùng chung namespace của Pod, cơ chế cân bằng tải mạng tĩnh Service và ba loại kiểm tra sức khỏe ứng dụng Probes.
- **[Chuyên đề 03: Quản lý cấu hình và Chính sách mạng](theory/03_k8s_config_network.md)**: Tách biệt cấu hình ứng dụng bằng ConfigMap/Secret và kiểm soát tường lửa nội bộ Ingress/Egress thông qua NetworkPolicy.

### [2. Cấu hình Tài nguyên](manifests/)
Thư mục chứa các mẫu manifest YAML thực hành để deploy trên cụm:
- **ConfigMap & Secret (`01_configmap.yaml`, `02_secret.yaml.example`)**: Tách biệt dữ liệu cấu hình và mật khẩu khỏi mã nguồn
- **Deployment Web (`03_deployment.yaml`)**: Khởi chạy ứng dụng Web dưới dạng Deployment để quản lý khả năng tự phục hồi, nhân bản (Scale) kết hợp cấu hình động và đầy đủ 3 loại Probes (Startup, Liveness, Readiness).
- **Service & NetworkPolicy (`04_service.yaml`, `05_networkpolicy.yaml`)**: Mở cổng truy cập bên ngoài và thắt chặt kết nối mạng đến các Pod được tạo bởi Deployment.

### [3. Cài đặt Môi trường](setup/)
Tài liệu hướng dẫn từng bước thiết lập môi trường giả lập trên Windows:
- **[Hướng dẫn thiết lập môi trường Kubernetes cục bộ](setup/local_environment.md)**: Quy trình tải Docker Desktop, minikube, kubectl qua winget và các lệnh CLI kiểm thử triển khai Pod nginx thực tế.

---

## Bằng chứng đối chiếu và Phản hồi
- Để xem tóm tắt kết quả tự học và phản hồi học tập chi tiết của ngày hôm nay (Thứ Ba, 02/06/2026), vui lòng kiểm tra: **[reflection.md](../reflection.md)**.
