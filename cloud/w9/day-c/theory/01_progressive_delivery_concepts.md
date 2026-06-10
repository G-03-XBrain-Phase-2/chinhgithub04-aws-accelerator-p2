# Chuyên đề 01: Khái niệm Progressive Delivery và So sánh Công cụ

## 1. Progressive Delivery là gì?

Progressive Delivery (Phát hành lũy tiến) là một bước tiến hóa của Continuous Delivery (CD). Kỹ thuật này cho phép chuyển dịch việc phát hành phần mềm mới từ trạng thái "tất cả hoặc không có gì" sang quy trình kiểm soát rủi ro có hệ thống.

Bằng cách giới hạn phạm vi tác động (blast radius) của phiên bản mới đối với người dùng cuối, Progressive Delivery tự động giám sát các chỉ số sức khỏe của ứng dụng, sau đó tăng dần lưu lượng truy cập (traffic) hoặc tự động thực hiện rollback lập tức nếu phát hiện chỉ số suy giảm.

Các chiến lược Progressive Delivery phổ biến bao gồm: Canary Deployments, Blue/Green Deployments, và Feature Flags.

---

## 2. So sánh các Chiến lược Deployment

### Kubernetes Rolling Update (Mặc định)
*   **Cơ chế**: Thay thế dần các Pod cũ bằng các Pod mới (ví dụ: tắt 1 Pod cũ, bật 1 Pod mới).
*   **Hạn chế**: 
    *   Không thể phân tách traffic chính xác theo tỉ lệ phần trăm (tỉ lệ traffic phụ thuộc vào tỉ lệ số lượng Pod cũ/mới).
    *   Không có cơ chế tự động giám sát metrics sức khỏe (như success rate, latency) để đưa ra quyết định tiếp tục rollout hay rollback. Nếu phiên bản mới bị lỗi logic sâu (chạy 5 phút mới crash), Rolling Update vẫn sẽ thay thế 100% Pod cũ bằng Pod lỗi.

### Blue/Green Deployment
*   **Cơ chế**: Khởi chạy một môi trường hoàn toàn mới độc lập (môi trường Green) song song với môi trường đang chạy thực tế (môi trường Blue). Khi môi trường Green đã sẵn sàng và vượt qua các bài test kiểm thử, traffic sẽ được chuyển hướng đột ngột 100% sang Green.
*   **Ưu điểm**: Rollback cực kỳ nhanh (chỉ cần chuyển hướng traffic ngược lại Blue).
*   **Nhược điểm**: Chi phí tài nguyên gấp đôi (phải chạy 2 hệ thống Pod song song trong quá trình deploy).

### Canary Deployment
*   **Cơ chế**: Triển khai một nhóm nhỏ Pod chạy phiên bản mới (Canary). Chỉ chuyển hướng một lượng nhỏ traffic (ví dụ: $5\%$, sau đó tăng lên $10\%$, $25\%$, $50\%$) sang Canary để đánh giá hiệu năng dựa trên metrics thực tế. Nếu an toàn, tăng dần tỉ lệ lên $100\%$.
*   **Ưu điểm**: Tiết kiệm tài nguyên hạ tầng, giới hạn tối đa số lượng người dùng bị ảnh hưởng nếu phiên bản mới bị lỗi.

### Bảng đối chiếu nhanh

| Tiêu chí | Rolling Update | Blue/Green | Canary |
| :--- | :--- | :--- | :--- |
| **Phân chia Traffic** | Không linh hoạt (dựa trên số lượng Pod) | 0% hoặc 100% lập tức | Tùy biến theo phần trăm ($1\% - 99\%$) |
| **Nhu cầu tài nguyên** | Thấp ($10\% - 25\%$ buffer) | Cao (gấp 2 lần - $100\%$ buffer) | Thấp ($10\% - 20\%$ buffer) |
| **Tự động Rollback** | Không tự động | Thủ công hoặc bán tự động | Tự động dựa trên Prometheus Metrics |
| **Blast Radius** | Lớn (ảnh hưởng toàn bộ người dùng) | Trung bình (phát hiện lỗi sau khi chuyển 100% traffic) | Rất nhỏ (chỉ ảnh hưởng nhóm nhỏ user thử nghiệm) |

---

## 3. So sánh Công cụ: Argo Rollouts vs Flagger

Argo Rollouts và Flagger là hai Controller GitOps hàng đầu chạy trong Kubernetes hỗ trợ Progressive Delivery:

### Argo Rollouts
*   **Kiến trúc**: Cung cấp Custom Resource Definition (CRD) dạng `Rollout` thay thế hoàn toàn cho tài nguyên `Deployment` tiêu chuẩn của Kubernetes.
*   **Đặc điểm**:
    *   Tích hợp trực tiếp và sâu sắc với ArgoCD.
    *   Cung cấp giao diện trực quan riêng biệt (Argo Rollouts Web UI / CLI plugin) để giám sát trạng thái và các bước phân chia traffic trực quan.
    *   Hỗ trợ nhiều cơ chế định tuyến (Ingress, Service Mesh) như AWS ALB Ingress, Nginx Ingress, Istio, Linkerd.

### Flagger
*   **Kiến trúc**: Không thay thế tài nguyên `Deployment`. Thay vào đó, Flagger sử dụng một CRD dạng `Canary` để giám sát và điều khiển tài nguyên `Deployment` có sẵn.
*   **Đặc điểm**:
    *   Hoạt động rất tốt với Flux CD và các pipeline CI/CD truyền thống.
    *   Phụ thuộc nhiều vào Service Mesh (Istio, Linkerd) hoặc Ingress controller để thực hiện chia traffic.
    *   Trọng lượng nhẹ, hoạt động ngầm (không có Web UI riêng, quản lý qua Prometheus Alertmanager hoặc Slack webhooks).

### Đề xuất lựa chọn
Trong hệ sinh thái đã lựa chọn **ArgoCD** làm GitOps Controller chủ đạo, **Argo Rollouts** là giải pháp đồng bộ và tối ưu nhất, cung cấp khả năng hiển thị trạng thái đồng bộ hoàn hảo trên bảng điều khiển.
