# Chuyên đề 01: Triết lý GitOps và So sánh Công cụ Điều phối

## 1. Khái niệm và Các Triết lý Cốt lõi của GitOps

GitOps là một mô hình vận hành và quản lý hạ tầng cũng như ứng dụng Kubernetes, trong đó hệ thống Git đóng vai trò là Single Source of Truth. Thay vì thực hiện các thay đổi trực tiếp trên cụm bằng các câu lệnh thủ công, mọi thay đổi đều được khai báo trong Git và tự động đồng bộ hóa xuống hệ thống đích.

Theo tiêu chuẩn định nghĩa bởi tổ chức OpenGitOps (CNCF), mô hình GitOps tuân thủ nghiêm ngặt 4 nguyên lý cốt lõi sau:

### Declarative State
Toàn bộ hệ thống phải được mô tả bằng ngôn ngữ khai báo (ví dụ: các manifest YAML của Kubernetes). Trạng thái này định nghĩa rõ ràng hệ thống mong muốn trông như thế nào (Desired State), chứ không chỉ ra các bước để tạo lập hệ thống đó.

### Versioned and Immutable
Bản mô tả trạng thái hệ thống phải được lưu trữ trong một hệ thống kiểm soát phiên bản hỗ trợ tính bất biến (phổ biến nhất là Git). Mọi thay đổi đều được ghi lại lịch sử rõ ràng qua các commit, cho phép auditing và rollback nhanh chóng.

### Pulled Automatically
Sau khi Declarative State được phê duyệt và lưu trữ trên Git, các agent chạy trực tiếp trong cụm K8s sẽ tự động kéo các cấu hình này về. Con người hoặc các hệ thống CI bên ngoài không cần can thiệp trực tiếp để đưa cấu hình vào cụm.

### Continuous Reconciliation
Agent liên tục giám sát sự khác biệt giữa trạng thái mong muốn (Desired State trên Git) và trạng thái thực tế (Actual State trên cụm). Khi xảy ra hiện tượng Configuration Drift, agent sẽ tự động thực hiện hành động điều hòa để đưa hệ thống thực tế trở lại đúng cấu hình trên Git (Self-healing).

---

## 2. So sánh Mô hình Push-based và Pull-based trong GitOps

Trong triển khai thực tế, có hai phương thức chính để áp dụng các thay đổi từ mã nguồn xuống cụm Kubernetes:

```text
[ Mô hình Push-based ]
  Developer ──► [ Git Repository ] ──► [ CI/CD System (GitHub Actions) ] ──► [ Kubernetes Cluster ]
                                                (kubectl apply / kubeconfig)

[ Mô hình Pull-based ]
  Developer ──► [ Git Repository ] ◄──────────────────────────────────────── [ Kubernetes Cluster ]
                                       (GitOps Agent - ArgoCD pulls & syncs)
```

### So sánh chi tiết

| Tiêu chí | Mô hình Push-based | Mô hình Pull-based |
| :--- | :--- | :--- |
| **Cơ chế hoạt động** | Hệ thống CI/CD bên ngoài (GitHub Actions, Jenkins) chủ động đẩy (apply) cấu hình trực tiếp vào API Server của cụm. | Một Agent chạy bên trong cụm (ArgoCD, Flux) liên tục kéo và áp dụng cấu hình từ Git Repo. |
| **Quản lý Credentials** | Kubeconfig hoặc API Token bảo mật cao của cụm K8s phải được lưu trữ trên hệ thống CI/CD bên ngoài. | Credentials được quản lý nội bộ trong cụm K8s. Agent giao tiếp với Git thông qua SSH Key hoặc HTTPS Token với quyền chỉ đọc (Read-only). |
| **Bảo mật mạng** | Cụm Kubernetes phải mở cổng API Server ra ngoài Internet để hệ thống CI/CD bên ngoài kết nối vào. | API Server của cụm có thể đóng hoàn toàn với Internet. Chỉ cần Agent có quyền truy cập Internet để kéo cấu hình từ Git. |
| **Xử lý Configuration Drift** | Không tự phát hiện được. Nếu ai đó sửa tay hạ tầng bằng `kubectl edit`, hệ thống CI/CD không biết cho đến khi có pipeline mới chạy. | Tự động phát hiện ngay lập tức. Tùy cấu hình, Agent sẽ tự động ghi đè (Self-heal) để đưa hệ thống về đúng thiết kế trên Git. |

---

## 3. So sánh Công cụ Điều phối: ArgoCD vs Flux CD

Cả ArgoCD và Flux CD đều là các công cụ GitOps mã nguồn mở hàng đầu được CNCF bảo trợ, vận hành theo mô hình Pull-based. Tuy nhiên, chúng có triết lý thiết kế và cách tiếp cận giao diện rất khác nhau:

### ArgoCD
*   **Triết lý**: Cung cấp một giải pháp GitOps trực quan, tập trung vào trải nghiệm người dùng và quản lý đa cụm thông qua giao diện Web UI mạnh mẽ.
*   **Đặc điểm kiến trúc**:
    *   Sử dụng Custom Resource Definition (CRD) dạng `Application` để định nghĩa liên kết giữa Git repository và Kubernetes namespace.
    *   Hỗ trợ giao diện Web UI hiển thị trực quan cấu trúc dạng cây của các tài nguyên (Deployment, ReplicaSet, Pod, Service) và trạng thái đồng bộ (Synced/OutOfSync).
    *   Có hệ thống phân quyền chi tiết (RBAC) tích hợp sẵn, phù hợp cho môi trường doanh nghiệp có nhiều team dùng chung.

### Flux CD (Flux v2)
*   **Triết lý**: Thiết kế theo triết lý UNIX - chia nhỏ thành các Controller chuyên biệt (GitRepository, HelmRelease, Kustomization) hoạt động độc lập và tận dụng tối đa cơ chế Native Kubernetes.
*   **Đặc điểm kiến trúc**:
    *   Không có giao diện Web UI chính thức mặc định (chủ yếu quản trị qua CLI `flux` và khai báo YAML).
    *   Phân tách rõ rệt vai trò: Source Controller lo việc tải mã nguồn, Kustomize Controller lo việc render manifest, Helm Controller lo việc cài đặt Helm Chart.
    *   Rất nhẹ, tiêu thụ ít tài nguyên và dễ dàng tích hợp sâu vào hạ tầng tự động hóa tự phát triển (Custom Platform).

### Bảng đối chiếu nhanh

| Tính năng | ArgoCD | Flux CD |
| :--- | :--- | :--- |
| **Giao diện Web UI** | Tích hợp sẵn, hiển thị trực quan, sinh động. | Không có sẵn (sử dụng CLI hoặc giao diện bên thứ ba). |
| **Quản lý Helm** | Tự động render Helm thành manifest thuần rồi apply. | Sử dụng Helm Controller riêng biệt để cài đặt Helm Native. |
| **Tính đa tài khoản (Multi-tenancy)** | Quản lý qua Web UI RBAC nội bộ của ArgoCD. | Sử dụng cơ chế RBAC sẵn có của Kubernetes một cách tự nhiên. |
| **Dấu chân tài nguyên (Resource Footprint)** | Trung bình (cần tài nguyên chạy Web Server, Redis cache). | Rất nhẹ (chỉ gồm các controller tính toán cơ bản). |
