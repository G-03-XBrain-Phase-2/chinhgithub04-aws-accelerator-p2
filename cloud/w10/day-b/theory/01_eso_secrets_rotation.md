# Chuyên đề 01: Secrets Rotation và External Secrets Operator (ESO)

## 1. Vấn đề của việc quản lý Secret truyền thống
Trong các cụm Kubernetes truyền thống, mật khẩu, khóa API và chứng chỉ số thường được lưu trữ dưới dạng tài nguyên `Secret`. 
*   **Hạn chế**: Dữ liệu trong `Secret` mặc định chỉ được mã hóa dưới dạng Base64 (dễ dàng giải mã bằng lệnh `echo -n <secret> | base64 -d`), dẫn đến nguy cơ cao bị rò rỉ nếu tệp YAML cấu hình vô tình bị đẩy lên các hệ thống quản lý mã nguồn (như GitHub).
*   **Khó khăn trong việc xoay vòng (Rotation)**: Việc thay đổi mật khẩu định kỳ yêu cầu can thiệp thủ công để cập nhật tệp YAML, apply lại vào cụm và khởi động lại Pod để nhận cấu hình mới.

---

## 2. Giải pháp Quản lý Secret Tập trung & External Secrets Operator (ESO)
Để giải quyết triệt để vấn đề trên, giải pháp chuẩn công nghiệp là sử dụng một dịch vụ quản lý Secret tập trung (như **AWS Secrets Manager**, HashiCorp Vault) kết hợp với **External Secrets Operator (ESO)** chạy trong cụm Kubernetes.

### Cơ chế hoạt động của ESO:
ESO liên tục theo dõi và đồng bộ các bí mật từ dịch vụ quản lý tập trung bên ngoài (AWS Secrets Manager) vào bên trong Kubernetes dưới dạng các K8s Secret native một cách tự động và bảo mật.

ESO định nghĩa các tài nguyên Custom Resource Definition (CRD) cốt lõi bao gồm:
*   **SecretStore**: Định nghĩa cách thức kết nối và xác thực tới nhà cung cấp Secret (như AWS Secrets Manager) trong phạm vi của một Namespace cụ thể.
*   **ClusterSecretStore**: Tương tự như `SecretStore` nhưng hoạt động ở phạm vi toàn cụm (Cluster-scoped), cho phép nhiều Namespace dùng chung cấu hình kết nối.
*   **ExternalSecret**: Định nghĩa cụ thể Secret nào cần lấy từ AWS Secrets Manager, tên của K8s Secret đích cần tạo ra trong cụm, và tần suất đồng bộ (`refreshInterval`).

---

## 3. Cơ chế Xoay vòng Secret không gây gián đoạn dịch vụ (Zero-Downtime Rotation)
Khi xoay vòng (rotate) mật khẩu trên AWS Secrets Manager, làm thế nào để ứng dụng chạy trong Pod lập tức nhận được mật khẩu mới mà không cần phải khởi động lại Pod (Zero-Downtime)?

### Phân tích hai cơ chế nạp Secret vào Container:

| Cơ chế nạp | Hành vi khi Secret thay đổi | Đánh giá bảo mật và vận hành |
| :--- | :--- | :--- |
| **Environment Variables (Biến môi trường)** | Pod **không thể** nhận giá trị mới trừ khi được restart hoàn toàn (làm tăng thời gian gián đoạn hoặc nguy cơ lỗi). | Kém an toàn (thông tin nhạy cảm dễ bị lộ qua các lệnh debug như `env` hoặc dump process). |
| **Volume Mount (Gắn tệp tin)** | Kubelet tự động cập nhật nội dung tệp tin Secret bên trong container (thông qua symlink) mà **không cần khởi động lại Pod**. | **Khuyên dùng**. Ứng dụng chỉ cần triển khai cơ chế lắng nghe thay đổi tệp tin (File Watcher) để tự động nạp lại cấu hình động. |

---

## 4. Khai báo YAML chuẩn mẫu

### File: `secret-store.yaml`
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: demo
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-southeast-1
      auth:
        # Sử dụng IRSA (IAM Roles for Service Accounts) để xác thực an toàn không cần dùng key tĩnh
        jwt:
          serviceAccountRef:
            name: eso-service-account
```

### File: `external-secret.yaml`
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-secret
  namespace: demo
spec:
  refreshInterval: "10s" # Đồng bộ tự động sau mỗi 10 giây
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: db-secret # K8s Secret native được tạo ra tự động
    creationPolicy: Owner
  data:
  - secretKey: password # Key trong K8s Secret
    remoteRef:
      key: prod/database/credentials # Tên Secret trên AWS Secrets Manager
      property: password # Key tương ứng bên trong JSON của AWS Secret
```
