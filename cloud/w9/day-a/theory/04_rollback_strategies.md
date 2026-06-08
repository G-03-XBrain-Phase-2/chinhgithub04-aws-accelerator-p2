# Chuyên đề 04: Chiến lược Khôi phục Trạng thái khi Gặp Sự cố (Rollback)

Khi triển khai phiên bản mới của ứng dụng lên môi trường Production và gặp sự cố nghiêm trọng, việc khôi phục nhanh chóng hệ thống về trạng thái ổn định gần nhất (Rollback) là yêu cầu tiên quyết. 

Trong môi trường Kubernetes chạy kết hợp mô hình GitOps, chúng ta có hai cách tiếp cận chính: **Imperative Rollback (`kubectl rollout undo`)** và **GitOps-way Rollback (`git revert`)**.

---

## 1. Phương pháp Truyền thống (Imperative): `kubectl rollout undo`

### Nguyên lý hoạt động
Phương pháp này can thiệp trực tiếp vào cụm thông qua CLI. Kube-controller-manager sẽ sử dụng lịch sử ReplicaSets được lưu trữ trong Kubernetes để hoán đổi nhanh nhãn Selector và chuyển đổi lượng traffic ngược về ReplicaSet cũ.

### Lệnh thực thi
```bash
kubectl rollout undo deployment/web-app
```

### Hạn chế nghiêm trọng trong mô hình GitOps
*   **Mất đồng bộ (Out of Sync)**: Đây là hạn chế lớn nhất. Khi chạy lệnh rollback trực tiếp trên cụm, manifest khai báo trên Git vẫn đang trỏ tới phiên bản lỗi. Khi ArgoCD thực hiện chu kỳ quét tiếp theo (hoặc khi bật chế độ Auto-Sync / Self-heal), ArgoCD sẽ phát hiện sự khác biệt và tự động ghi đè (overwrite) phiên bản cũ, đưa phiên bản lỗi trở lại cụm.
*   **Thiếu lịch sử ghi nhận (No Auditing)**: Không có thông tin lưu vết trên Git giải thích tại sao hệ thống bị rollback, ai đã thực hiện lệnh và vào lúc nào.
*   **Phạm vi áp dụng hạn chế**: Lệnh `kubectl rollout` chỉ hoạt động với một số loại tài nguyên có cơ chế lưu lịch sử như Deployments, StatefulSets và DaemonSets. Nó hoàn toàn bất lực nếu lỗi xuất hiện ở ConfigMap, Secrets hoặc NetworkPolicies.

---

## 2. Phương pháp Chuẩn GitOps: `git revert`

### Nguyên lý hoạt động
Đúng với triết lý Git là Single Source of Truth, việc rollback được thực hiện bằng cách thay đổi trực tiếp mã nguồn trên Git thông qua lệnh tạo commit đảo ngược (`git revert`). Khi mã nguồn cũ (ổn định) được đẩy lên nhánh chính, Agent của GitOps (ArgoCD/Flux) sẽ tự động sync nó xuống cụm.

### Quy trình thực hiện
1.  **Xác định commit lỗi**: Tìm hash của commit vừa gây lỗi.
2.  **Tạo commit đảo ngược**:
    ```bash
    git revert <bad-commit-hash>
    ```
3.  **Đẩy lên Git**: Push commit revert lên nhánh `main`.
4.  **Tự động đồng bộ**: ArgoCD phát hiện sự thay đổi trên Git và tự động đồng bộ (Sync) đưa cụm về trạng thái ổn định cũ.

### Ưu điểm vượt trội
*   **Đồng bộ tuyệt đối (In Sync)**: Trạng thái khai báo trên Git và trạng thái thực tế trên cụm Kubernetes luôn khớp nhau 100%.
*   **Ghi vết đầy đủ**: Lịch sử Git ghi nhận rõ ràng commit đảo ngược, tạo điều kiện cho việc phân tích nguyên nhân gốc rễ (Post-mortem) sau sự cố.
*   **Hỗ trợ toàn diện**: Áp dụng được cho mọi tài nguyên K8s (ConfigMap, Secret, Service, Ingress...) vì bản chất là Git thay đổi cấu hình YAML.
*   **Quy trình an toàn**: Không yêu cầu kỹ sư vận hành phải có quyền truy cập trực tiếp (`kubeconfig`) vào cụm Production, giảm thiểu rủi ro bảo mật.

---

## 3. Bảng So sánh và Đánh giá Lựa chọn

| Tiêu chí | `kubectl rollout undo` (Imperative) | `git revert` (GitOps-way) |
| :--- | :--- | :--- |
| **Tốc độ thực thi** | Rất nhanh (tác động trực tiếp vào API Server của cụm). | Chậm hơn một chút (phải qua bước commit, push và đợi chu kỳ quét/sync của GitOps). |
| **Nguồn sự thật (Source of Truth)** | Bị phá vỡ (cụm chạy phiên bản cũ nhưng Git vẫn khai báo phiên bản lỗi). | Được duy trì nhất quán giữa Git và Cụm (In Sync). |
| **Lưu vết lịch sử** | Chỉ lưu tạm thời trong etcd của K8s (bị giới hạn số lượng revision). | Lưu vĩnh viễn trên Git History. |
| **Yêu cầu phân quyền** | Kỹ sư phải có quyền ghi (Write) trực tiếp vào cụm Production. | Kỹ sư chỉ cần quyền ghi trên Git Repository. |
| **Tự động khôi phục (Self-healing)** | Bị vô hiệu hóa hoặc gây xung đột vòng lặp với ArgoCD. | Hoạt động hoàn hảo và phối hợp nhịp nhàng với ArgoCD. |

### Đề xuất khuyến nghị
Trong môi trường Production vận hành theo GitOps, **`git revert` luôn là lựa chọn chuẩn mực và bắt buộc**. Chỉ sử dụng `kubectl rollout undo` làm giải pháp ứng cứu khẩn cấp trong trường hợp Git Repo bị sập hoàn toàn, và sau khi cụm hoạt động lại, lập tức phải cập nhật Git cho khớp với thực tế cụm.
