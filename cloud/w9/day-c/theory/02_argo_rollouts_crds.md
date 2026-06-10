# Chuyên đề 02: Cấu trúc Tài nguyên Rollout CRD và Cơ chế Định tuyến

Để triển khai Progressive Delivery, Argo Rollouts giới thiệu Custom Resource Definition (CRD) có tên là `Rollout`. Tài nguyên này thay thế tài nguyên `Deployment` tiêu chuẩn của Kubernetes để quản lý vòng đời của Pod.

---

## 1. Kubernetes Deployment vs Argo Rollout CRD

Về mặt cấu trúc, tệp cấu hình của `Rollout` tương thích ngược gần như hoàn toàn với `Deployment`. Phần `spec.template` (định nghĩa container, images, environment variables, ports) được giữ nguyên. 

Điểm khác biệt cốt lõi nằm ở trường `spec.strategy`:
*   `Deployment` chỉ hỗ trợ chiến lược `RollingUpdate` hoặc `Recreate`.
*   `Rollout` hỗ trợ chiến lược `canary` hoặc `blueGreen` với khả năng điều khiển chi tiết từng bước chuyển dịch lưu lượng truy cập.

---

## 2. Phân tích Cấu trúc Strategy Canary trong Rollout

Dưới đây là một tệp YAML cấu hình chiến lược Canary mẫu của tài nguyên `Rollout`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: web-app-rollout
spec:
  replicas: 5
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: nginx:1.25.1
        ports:
        - name: http
          containerPort: 80
  strategy:
    canary:
      stableService: web-app-stable  # Service trỏ tới các Pod chạy phiên bản cũ ổn định
      canaryService: web-app-canary  # Service trỏ tới các Pod chạy phiên bản mới thử nghiệm
      trafficRouting:
        nginx:
          stableIngress: web-app-ingress # Tích hợp với Ingress để chia traffic thực tế
      steps:
      - setWeight: 10              # Chuyển 10% traffic sang phiên bản mới
      - pause: { duration: 5m }    # Tạm dừng 5 phút để theo dõi hiệu năng
      - setWeight: 30              # Tăng traffic canary lên 30%
      - pause: {}                  # Tạm dừng vô thời hạn cho đến khi được phê duyệt thủ công
      - setWeight: 60
      - pause: { duration: 10m }
```

### Các thuộc tính chính trong `steps`
*   **setWeight**: Thiết lập tỉ lệ phần trăm lưu lượng truy cập tối đa được phép chuyển hướng sang nhóm Pod chạy phiên bản mới (Canary).
*   **pause**: Chỉ định thời gian tạm dừng của bước hiện tại trước khi tự động chuyển sang bước tiếp theo:
    *   Nếu có tham số `duration` (ví dụ: `5m` - 5 phút): Hệ thống sẽ tự động chuyển sang bước tiếp theo sau khi hết thời gian.
    *   Nếu để trống `pause: {}`: Hệ thống sẽ tạm dừng vô thời hạn (Promote Pause), yêu cầu quản trị viên chạy lệnh phê duyệt thủ công (ví dụ: `kubectl argo rollouts promote web-app-rollout`) thì mới chạy tiếp.

---

## 3. Luồng Định tuyến Lưu lượng (Traffic Routing)

Để thực hiện chia tách traffic động (ví dụ: $90\%$ vào Stable Pods và $10\%$ vào Canary Pods) mà không bị ảnh hưởng bởi tỉ lệ số lượng Pod thực tế, Argo Rollouts cần sự hỗ trợ của hai dịch vụ Kubernetes Service song song kết hợp với một Ingress Controller (như Nginx Ingress hoặc AWS ALB) hoặc Service Mesh:

```text
                    [ External Traffic / Ingress ]
                                   │
                ┌──────────────────┴──────────────────┐
                │ (Split Traffic - e.g., 90% vs 10%)  │
                ▼                                     ▼
       [ Stable Service ]                     [ Canary Service ]
               │                                      │
               ▼                                      ▼
         [ Stable Pods ]                        [ Canary Pods ]
         (Active Version)                       (New Version)
```

1.  **Stable Service (`web-app-stable`)**: Chịu trách nhiệm dẫn traffic thực tế của đại đa số người dùng ($90\% - 99\%$) vào các Pod phiên bản ổn định.
2.  **Canary Service (`web-app-canary`)**: Dẫn một lượng nhỏ traffic thử nghiệm ($1\% - 10\%$) vào các Pod phiên bản mới.
3.  **Ingress / Service Mesh**: Nơi trực tiếp can thiệp vào tầng HTTP routing để phân chia chính xác tỉ lệ phần trăm traffic theo cấu hình `setWeight` quy định trong các bước (steps) của Rollout.
