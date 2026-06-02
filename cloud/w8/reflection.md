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

---

### Thứ Tư, 03/06/2026 — Day C: State Management, Modules & Live Q&A
*(Sẽ cập nhật chi tiết sau khi hoàn thành ngày học Day C)*
