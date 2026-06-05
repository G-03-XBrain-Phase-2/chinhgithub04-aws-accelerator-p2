# W8 Learning Journal & Reflection — Foundation: IaC & K8s

*   **Họ và tên:** Nguyễn Đức Chinh
*   **ID:** XB-DN26-080
*   **Group:** 3
*   **Tuần học:** Tuần 08 (01/06/2026 – 05/06/2026)
*   **Chuyên ngành:** Cloud / DevOps

---

## Nhật ký Học tập Hàng ngày (Daily Journal)

### Thứ Hai, 01/06/2026 — Day A: Terraform Foundations
> **Nhiệm vụ:** Tự học lý thuyết IaC, Workflow cơ bản, cú pháp HCL và cơ chế State & Drift của Terraform.

#### 1. Lý thuyết thu hoạch được (Core Theoretical Takeaways)
*   **Bản chất IaC**: Nắm rõ mô hình **Declarative (Khai báo)** của Terraform so với Imperative (Mệnh lệnh) của Ansible/Script. Việc khai báo trạng thái mong muốn giúp hệ thống tự động xử lý Idempotency, quản lý vòng đời tài nguyên một cách tối ưu.
*   **Cơ chế đồ thị (DAG)**: Hiểu được nguyên lý Terraform gộp toàn bộ file `.tf` trong thư mục hoạt động và phân tích các tham chiếu thuộc tính để vẽ nên **Đồ thị có hướng không chu trình (DAG)**, giúp thực thi tài nguyên song song và quản lý phụ thuộc (Implicit/Explicit Dependencies) mà không phụ thuộc vào thứ tự đặt tên tệp tin.
*   **Arguments vs Attributes**: Phân biệt rõ Arguments là cấu hình cấu trúc đầu vào viết trong code (ví dụ: `algorithm = "RSA"`), còn Attributes là các thuộc tính đầu ra chỉ được sinh ra sau khi tạo tài nguyên thành công ở runtime (ví dụ: `private_key_pem`).
*   **State & Drift**: Hiểu được `terraform.tfstate` là bản đồ ánh xạ thế giới thực và là cache hiệu năng. Lệch cấu hình (Drift) xảy ra khi reality bị sửa đổi ngoài luồng. Có 2 cách sửa: áp dụng lại cấu hình để ghi đè thực tế (reconcile) hoặc cập nhật code cho khớp thực tế. Nắm vững cách dùng tham số `-replace` để ép buộc hủy đi tạo lại tài nguyên an toàn.

#### 2. Kết quả thực hành (Practical Checkpoint Evidence)
Em đã xây dựng một tổ hợp thực hành nâng cao an toàn (sử dụng local file và cryptographic key generator) tại thư mục `cloud/w8/day-a/practice/` và hoàn thành các thí nghiệm kiểm chứng:
*   [x] Khởi tạo (`init`) thành công, khóa phiên bản provider bằng `.terraform.lock.hcl`.
*   [x] Triển khai thành công cấu hình truyền thuộc tính runtime (Attribute of TLS resource -> Argument of Local File) và kiểm chứng quan hệ phụ thuộc trong đồ thị DAG.
*   [x] **Kiểm chứng Drift**: Thay đổi trực tiếp file `project_metadata.json` bên ngoài, chạy `plan` thấy Terraform cảnh báo chính xác sự thay đổi thuộc tính, chạy `apply` và khôi phục (reconcile) thành công về trạng thái định nghĩa ban đầu.
*   [x] **Kiểm chứng Replace**: Chạy thành công lệnh `terraform apply -replace="local_file.secure_credential_file"` để ép buộc tái tạo lại khóa bảo mật cục bộ.

---

### Thứ Ba, 02/06/2026 — Day B: Kubernetes Architecture & Local Setup
> **Nhiệm vụ:** Tự học lý thuyết kiến trúc Kubernetes, các loại tài nguyên cốt lõi (Pod, Service, Probes), cấu hình bảo mật mạng (ConfigMap, Secret, NetworkPolicy) và thiết lập môi trường chạy thử nghiệm cục bộ.

#### 1. Lý thuyết thu hoạch được (Core Theoretical Takeaways)
- **Kiến trúc hệ thống**: Nắm rõ vai trò của Control Plane trong việc ra quyết định toàn cục (lập lịch, điều khiển trạng thái) và Worker Node trong việc thực thi container. Hiểu sâu cơ chế tương tác thông qua watch event của API Server và cách lưu trữ trạng thái tại etcd.
- **Tài nguyên Pod & Service**: Hiểu rõ Pod là đơn vị chia sẻ chung network/storage namespace giữa các container. Nắm vững cách phân phối lưu lượng của Service thông qua Selector, phân biệt rõ các loại Service (ClusterIP để giao tiếp nội bộ, NodePort để mở cổng trên node và LoadBalancer để tích hợp đám mây).
- **Probes**: Phân biệt vai trò của ba loại Probe trong giám sát sức khỏe container: Startup Probe (chỉ chạy khi khởi động), Liveness Probe (giữ container sống, tự khởi động lại khi treo) và Readiness Probe (ngăn traffic lỗi đi vào container chưa sẵn sàng).
- **ConfigMap/Secret & NetworkPolicy**: Nhận thức được Base64 của Secret chỉ là mã hóa định dạng (encoding), cần áp dụng mã hóa dữ liệu lưu trữ (Encryption at Rest) và phân quyền RBAC chặt chẽ. Hiểu nguyên lý hoạt động của NetworkPolicy giúp thiết lập tường lửa cô lập mạng giữa các Pod dựa trên nhãn nhắm tới.

#### 2. Kết quả thực hành (Practical Checkpoint Evidence)
Em đã hoàn thành việc thiết lập và kiểm tra môi trường cục bộ trên hệ điều hành Windows:
- [x] Cài đặt Docker Desktop, minikube và kubectl thông qua Windows Package Manager (`winget`).
- [x] Khởi động thành công cụm Kubernetes cục bộ: `minikube start --driver=docker`.
- [x] Thực thi triển khai thử nghiệm một nginx Pod, expose cổng thông qua dịch vụ NodePort và truy cập thành công qua URL được cấp bởi minikube, sau đó làm sạch tài nguyên thử nghiệm.
- [x] Soạn thảo bộ các tệp cấu hình YAML mẫu (`manifests/`) chuẩn hóa cho ConfigMap, Secret, Pod (kèm Probes/Env), Service NodePort và NetworkPolicy.

---

### Thứ Tư, 03/06/2026 — Day C: State Management, Modules & Live Q&A
> **Nhiệm vụ:** Tự học lý thuyết Terraform nâng cao (Remote State & Locking, Modules, Best Practices & ADR), xây dựng cấu hình phân chia môi trường thực hành mẫu, tham gia buổi Live Q&A cùng Mentor Minh và hoàn thành bài kiểm tra trắc nghiệm Online Test 1.

#### 1. Lý thuyết thu hoạch được (Core Theoretical Takeaways)
- **Remote State & Locking**: Hiểu rõ sự cần thiết của việc đưa tệp State lên lưu trữ tập trung tại AWS S3 để làm việc nhóm đồng bộ và bật Versioning tránh mất mát dữ liệu. Nắm vững cơ chế hoạt động của State Locking thông qua thuộc tính khóa `LockID` ở bảng DynamoDB giúp ngăn chặn hiện tượng Race Condition (xung đột ghi đè song song).
- **Cấu trúc Modules**: Thấu hiểu triệt để nguyên lý DRY (Don't Repeat Yourself) khi đóng gói tài nguyên hạ tầng. Nắm chắc cấu trúc đóng gói biệt lập của Child Module qua 3 tệp tiêu chuẩn (`main.tf`, `variables.tf`, `outputs.tf`) và cách gọi module qua các nguồn cục bộ (Local) hoặc từ xa (Git, Registry).
- **Best Practices & ADR**: Áp dụng quy chuẩn đặt tên nhất quán, bảo mật thông tin nhạy cảm qua Secret Manager, và phân tách các môi trường triển khai thực tế bằng cấu trúc thư mục (Directory-based Isolation) để tăng tính minh bạch. Hiểu rõ mục đích và cấu trúc của tài liệu ADR giúp lưu vết lịch sử các thay đổi kiến trúc quan trọng của hệ thống.

#### 2. Kết quả thực hành (Practical Checkpoint Evidence)
- [x] Thiết lập thành công Custom Module cục bộ tại `practice/modules/s3_static_website/` thực hiện cấu hình AWS S3 Bucket, chính sách công khai Bucket Policy và Website Configuration.
- [x] Thiết lập phân vùng môi trường phát triển mẫu tại `practice/environments/dev/` với cấu hình lưu trữ Remote Backend trỏ về AWS S3/DynamoDB và thực hiện gọi truyền dữ liệu cho Child Module cục bộ.
- [x] Tham gia buổi Live Q&A thảo luận trực tuyến cùng Mentor Minh để tháo gỡ các vướng mắc thực tế.
- [x] Hoàn thành bài trắc nghiệm Online Test 1 (thời gian 60 phút) kiểm tra toàn bộ kiến thức nền tảng của Terraform phần 1.

---

### Thứ Sáu, 05/06/2026 — Onsite Lab: Tự động hóa cụm K8s trên EC2 & ALB
> **Nhiệm vụ:** Thiết kế và xây dựng giải pháp tự động hóa 1-click dựng hạ tầng AWS EC2, cài đặt cụm Kubernetes (Kind), tự động wire `kubernetes` provider cục bộ để deploy ứng dụng web và định tuyến lưu lượng qua Application Load Balancer (ALB).

#### 1. Lý thuyết thu hoạch được (Core Theoretical Takeaways)
- **Tích hợp Multi-Provider động**: Thấu hiểu cách Terraform giải quyết việc trì hoãn khởi tạo (defer initialization) một provider khi cấu hình của nó phụ thuộc vào đầu ra của một tài nguyên chưa được tạo ra. Hiểu rõ sự kết hợp của `external` data source để trích xuất cấu hình nhạy cảm (`kubeconfig`) từ xa.
- **Ánh xạ mạng liên tầng (Host-to-Container Routing)**: Nắm chắc phương thức ánh xạ cổng từ container của cụm Kind ra cổng vật lý của máy host EC2 (`extraPortMappings`). Hiểu được cơ chế hoạt động của ALB Target Group kiểu `instance` để phân phối lưu lượng từ internet vào cổng NodePort cụm Kubernetes.
- **Quản lý khóa SSH tự động**: Nhận thức được tầm quan trọng của việc sinh khóa động (`tls_private_key`) để cô lập bảo mật trên môi trường lab và loại bỏ việc sử dụng các file khóa tĩnh dễ bị rò rỉ.

#### 2. Kết quả thực hành (Practical Checkpoint Evidence)
- [x] Xây dựng thành công hạ tầng mạng VPC hoàn chỉnh bao gồm Route Tables và Security Groups phân tách luồng traffic cho ALB và EC2 Host.
- [x] Triển khai máy ảo EC2 chạy kịch bản khởi tạo SSH tự động cài đặt Docker, Kind, kubectl và kích hoạt cụm Kind tích hợp Public IP vào Certificate SANs.
- [x] Xây dựng script PowerShell chạy cục bộ trích xuất base64 CA/Client certs từ EC2 và liên kết động thành công vào `kubernetes` provider.
- [x] Triển khai ứng dụng Web Nginx có tùy biến mã nguồn trang HTML qua `kubernetes_config_map` và expose thành công qua `kubernetes_service` loại NodePort cổng `30080`.
- [x] Hoàn thiện tài liệu hướng dẫn vận hành chi tiết và sơ đồ kiến trúc tại tệp tin `README.md` của thư mục lab.
- [x] Thử nghiệm thành công chuỗi tự hủy tài nguyên thông qua lệnh `terraform destroy` giúp tối ưu hóa chi phí vận hành đám mây.

