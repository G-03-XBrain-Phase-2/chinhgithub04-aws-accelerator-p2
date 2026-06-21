# Chuyên đề 04: Xác thực Chữ ký ảnh tại Admission Control (Sigstore Policy Controller)

## 1. Tại sao cần kiểm tra chữ ký tại Admission Control?
*   **Bypass CI/CD**: Ngay cả khi CI pipeline đã được bảo mật để chỉ build và ký các ảnh sạch, một lập trình viên có quyền truy cập cụm vẫn có thể chạy lệnh `kubectl run` hoặc `kubectl apply` để triển khai một ảnh chưa qua kiểm duyệt hoặc chứa mã độc từ máy cá nhân.
*   **Chốt chặn cuối cùng (Last Line of Defense)**: Admission Control hoạt động trực tiếp tại Kubernetes API Server, kiểm duyệt mọi yêu cầu tạo/sửa đổi tài nguyên bất kể nguồn gốc yêu cầu từ đâu, đảm bảo 100% tài nguyên chạy trong cụm tuân thủ chính sách.

---

## 2. Sigstore Policy Controller
**Sigstore Policy Controller** hoạt động như một Admission Controller Webhook chạy trong cụm Kubernetes.
*   Nhiệm vụ của nó là chặn đứng các yêu cầu tạo Pod ở bước Validating Webhook nếu ảnh container khai báo trong Pod không vượt qua được bước kiểm tra chữ ký số đối chiếu với các chính sách được định nghĩa trước.
*   Để tối ưu hóa hiệu năng, chính sách xác thực thường chỉ kích hoạt trên các Namespace được dán nhãn cụ thể (ví dụ: `policy.sigstore.dev/include=true`).

---

## 3. Cấu hình ClusterImagePolicy (Chính sách xác thực cấp Cụm)
Chúng ta định nghĩa chính sách xác thực thông qua tài nguyên `ClusterImagePolicy`.

### Ví dụ về chính sách bắt buộc ảnh nội bộ phải được ký bởi khóa của công ty:
```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: enforce-company-signature
spec:
  images:
    # Chỉ áp dụng kiểm tra chữ ký đối với các ảnh thuộc registry nội bộ
    - glob: "ghcr.io/chinhgithub04/w10-api**"
  authorities:
    - key:
        data: |
          -----BEGIN PUBLIC KEY-----
          MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAELOb1NKYuAeUD2CXYGmV4PLwCjodJ
          nZvNpMXnJNkPjRAtWL4/zkPD8D930GsWqHh+9aX/ZDjBMB7EhkQGfoIxDg==
          -----END PUBLIC KEY-----
```

---

## 4. Chính sách Ngoại lệ (Exception Policies)
Cụm Kubernetes luôn cần chạy các ảnh hệ thống (CoreDNS, kube-proxy, aws-node) hoặc các ảnh từ bên thứ ba (nginx, python, redis). Các ảnh này chắc chắn không được ký bằng khóa riêng tư của chúng ta.

*   **Giải pháp**: Định nghĩa một chính sách ngoại lệ khớp với toàn bộ các ảnh còn lại (`**`) hoặc các registry tin cậy bên ngoài và gán hành động tĩnh là **Pass** (cho phép chạy qua không cần verify).

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: allow-third-party-images
spec:
  images:
    - glob: "**" # Khớp tất cả các ảnh còn lại
  authorities:
    - static:
        action: pass # Cho phép chạy qua trực tiếp
```

---

## 5. Cơ chế Fail-Closed và Fail-Open của Webhook
Khi cấu hình Admission Webhook (`ValidatingWebhookConfiguration`), tham số `failurePolicy` đóng vai trò quyết định hành vi của hệ thống khi dịch vụ Webhook (Sigstore Policy Controller) gặp sự cố (bị sập, mất mạng, quá tải):

| Chế độ | Hành vi khi Webhook sập | Đánh giá bảo mật và sẵn sàng |
| :--- | :--- | :--- |
| **Fail-Open (`failurePolicy: Ignore`)** | API Server bỏ qua kiểm duyệt và **cho phép** Pod được tạo bình thường. | Ưu tiên tính sẵn sàng của hệ thống (High Availability), nhưng tạo ra kẽ hở bảo mật lớn khi webhook gặp sự cố. |
| **Fail-Closed (`failurePolicy: Fail`)** | API Server **chặn đứng** mọi yêu cầu tạo Pod mới và trả về lỗi. | **Chuẩn bảo mật cao (Khuyên dùng)**. Thà hy sinh tính sẵn sàng tạm thời của việc deploy mới còn hơn để lọt một container độc hại không rõ nguồn gốc vào cụm. |
