# Chuyên đề 03: Quản lý cấu hình và Chính sách mạng trong Kubernetes — ConfigMap, Secret và NetworkPolicy

Để đảm bảo các ứng dụng chạy trên Kubernetes có tính linh hoạt cao và được bảo mật tốt, chúng ta cần tách biệt phần mã nguồn khỏi phần cấu hình hệ thống, đồng thời kiểm soát chặt chẽ các luồng giao tiếp mạng giữa các Pod.

---

## 1. ConfigMap và Secret — Tách biệt cấu hình và bảo mật

Kubernetes cung cấp hai đối tượng tài nguyên để tiêm (inject) cấu hình vào container tại thời điểm runtime mà không cần xây dựng lại Docker image.

### Bản chất của hai tài nguyên

#### ConfigMap
- **Mục đích**: Lưu trữ các dữ liệu cấu hình không nhạy cảm dưới dạng các cặp key-value (ví dụ: file cấu hình ứng dụng, biến môi trường, tham số chạy thử nghiệm).
- **Hạn chế**: Dung lượng tối đa là 1MB và dữ liệu được lưu trữ dạng plain text.

#### Secret
- **Mục đích**: Lưu trữ các thông tin nhạy cảm đòi hỏi tính bảo mật (ví dụ: mật khẩu, API keys, SSH keys, chứng chỉ SSL).
- **Cơ chế**: Dữ liệu lưu trong tệp cấu hình YAML của Secret bắt buộc phải được mã hóa dưới dạng **Base64**. Tuy nhiên, Base64 chỉ là một chuẩn mã hóa dữ liệu (encoding), không phải giải pháp bảo mật mật mã (encryption). Bất kỳ ai có quyền truy cập vào YAML của Secret đều có thể dễ dàng giải mã ngược về plain text bằng lệnh `echo "<base64_string>" | base64 --decode`.

### Cơ chế truyền cấu hình vào Container
Chúng ta có hai cách chính để đưa dữ liệu từ ConfigMap/Secret vào trong container:
1. **Biến môi trường (Environment Variables)**: Ánh xạ trực tiếp giá trị của các key thành các biến môi trường trong container. Thích hợp cho cấu hình dạng giá trị đơn lẻ.
2. **Ổ đĩa gắn kết (Mounted Volumes)**: Gắn kết ConfigMap hoặc Secret thành một thư mục chứa các tệp tin trong container. Mỗi key trong cấu hình sẽ trở thành tên một tệp tin, và giá trị tương ứng sẽ là nội dung tệp tin đó. Điểm cộng của cách này là khi cập nhật ConfigMap/Secret, nội dung các tệp tin trong container sẽ tự động được cập nhật mà không cần khởi động lại Pod.

### Các lưu ý bảo mật quan trọng đối với Secret
Để bảo vệ các thông tin nhạy cảm của hệ thống, ta cần triển khai các lớp phòng thủ bổ sung:
- **RBAC (Role-Based Access Control)**: Giới hạn tối đa quyền truy cập (GET, LIST) vào các đối tượng Secret. Chỉ cho phép các Pod hoặc ServiceAccount thực sự cần thiết được quyền đọc Secret.
- **Encryption at Rest (Mã hóa lưu trữ)**: Cấu hình để Kubernetes tự động mã hóa dữ liệu Secret trước khi ghi xuống đĩa cứng của cơ sở dữ liệu `etcd`.
- **Giải pháp bên ngoài (External Secret Providers)**: Sử dụng các dịch vụ quản lý khóa chuyên nghiệp (như AWS Secrets Manager, HashiCorp Vault) kết hợp với các công cụ như External Secrets Operator để đồng bộ khóa an toàn vào cụm.

---

## 2. NetworkPolicy — Kiểm soát giao tiếp mạng giữa các Pod

Theo mặc định trong Kubernetes, mạng lưới được thiết kế phẳng (non-isolated): **Tất cả các Pod trong cụm có thể tự do kết nối và gửi traffic tới nhau mà không gặp bất kỳ rào cản nào**. Để thiết lập tường lửa nội bộ và tuân thủ các chuẩn an ninh, ta sử dụng tài nguyên **NetworkPolicy**.

### Nguyên lý hoạt động
- NetworkPolicy hoạt động như một bộ lọc traffic (tương tự Security Group trong AWS) ở tầng Network (Lớp 3 và Lớp 4 OSI).
- Để sử dụng NetworkPolicy, cụm Kubernetes bắt buộc phải chạy một **Network Plugin (CNI)** hỗ trợ NetworkPolicy (như Calico, Cilium, Weave Net). Nếu CNI mặc định không hỗ trợ, việc cấu hình NetworkPolicy sẽ không có tác dụng.
- **Default Deny**: Thực hành tốt nhất (Best Practice) về bảo mật là cấu hình chặn toàn bộ kết nối mặc định cho một Namespace, sau đó chỉ mở dần các kết nối được phép (Least Privilege).

### Các loại luật định cấu hình
- **Ingress (Lưu lượng đi vào)**: Kiểm soát những nguồn nào được phép kết nối đến các Pod mục tiêu.
- **Egress (Lưu lượng đi ra)**: Kiểm soát những đích nào mà các Pod mục tiêu được phép kết nối tới.

### Cơ chế lựa chọn đối tượng (Selectors)
NetworkPolicy sử dụng các bộ lọc linh hoạt để xác định nguồn và đích của traffic:
1. **podSelector**: Lọc các Pod dựa trên nhãn (labels) nằm trong cùng một Namespace.
2. **namespaceSelector**: Lọc toàn bộ các Pod thuộc về một Namespace có nhãn phù hợp.
3. **ipBlock**: Lọc dựa trên dải địa chỉ IP mạng (CIDR) cụ thể (thường dùng để cho phép kết nối ra ngoài Internet hoặc dải mạng ngoài cụm).

### Cấu hình mẫu NetworkPolicy bảo mật cho Database
Cấu hình dưới đây chỉ cho phép các Pod có nhãn `role: frontend` thuộc Namespace có nhãn `env: staging` được kết nối đến cổng 5432 của Pod database:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-security-policy
  namespace: database-ns
spec:
  # Áp dụng chính sách này cho các Pod có nhãn role: postgres
  podSelector:
    matchLabels:
      role: postgres
  policyTypes:
  - Ingress
  ingress:
  # Luật cho phép lưu lượng đi vào
  - from:
    # Lọc Namespace nguồn có nhãn env: staging
    - namespaceSelector:
        matchLabels:
          env: staging
      # Lọc Pod nguồn có nhãn role: frontend nằm trong Namespace trên
      podSelector:
        matchLabels:
          role: frontend
    ports:
    # Chỉ mở cổng 5432 với giao thức TCP
    - protocol: TCP
      port: 5432
```
