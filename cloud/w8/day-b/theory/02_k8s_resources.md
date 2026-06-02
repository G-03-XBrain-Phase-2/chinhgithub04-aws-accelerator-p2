# Chuyên đề 02: Các tài nguyên cốt lõi trong Kubernetes — Pod, Service và Probes

Để triển khai và vận hành ứng dụng trên Kubernetes, ta cần nắm vững cách hoạt động của các đối tượng tài nguyên cơ bản cấu thành nên vòng đời và cơ chế định tuyến mạng của ứng dụng.

---

## 1. Pod — Đơn vị tính toán nhỏ nhất

Pod là khối xây dựng cơ bản và nhỏ nhất trong mô hình tài nguyên của Kubernetes. 

### Bản chất của Pod
- Một Pod đại diện cho một tiến trình đang chạy trong cụm. Nó có thể chứa một hoặc nhiều container (thường là một container chính và có thể kèm theo các container phụ trợ như sidecar).
- Các container trong cùng một Pod chia sẻ chung các tài nguyên hệ thống:
  - **Network Namespace**: Dùng chung một địa chỉ IP nội bộ (Pod IP), dải cổng (ports). Các container giao tiếp với nhau qua `localhost`.
  - **Storage (Volumes)**: Có thể chia sẻ chung các ổ đĩa để trao đổi dữ liệu trực tiếp với tốc độ cao.
  - **IPC Namespace**: Cho phép các tiến trình giao tiếp trực tiếp qua bộ nhớ chia sẻ.

---

## 2. Service — Cơ chế định tuyến và cân bằng tải

Do Pod có vòng đời ngắn (ephemeral) — có thể bị hủy, di dời hoặc tạo mới bất kỳ lúc nào với các địa chỉ IP thay đổi liên tục — nên chúng ta cần một cơ chế định tuyến ổn định để kết nối tới chúng. **Service** sinh ra để giải quyết vấn đề này bằng cách cung cấp một IP tĩnh và cơ chế cân bằng tải đến tập hợp các Pod đích thông qua Selector.

### Các loại Service cơ bản

#### ClusterIP (Mặc định)
- **Mục đích**: Định tuyến lưu lượng mạng nội bộ trong cụm Kubernetes.
- **Cơ chế**: Cụm sẽ cấp một địa chỉ IP ảo nội bộ (Virtual IP). Các dịch vụ khác trong cụm chỉ cần kết nối tới IP này hoặc dùng tên miền DNS nội bộ (ví dụ: `my-service.my-namespace.svc.cluster.local`) để truy cập vào các Pod. Không thể truy cập ClusterIP từ bên ngoài cụm.

#### NodePort
- **Mục đích**: Expose dịch vụ ra bên ngoài cụm bằng cách ánh xạ cổng của Service vào một cổng tĩnh trên tất cả các Worker Nodes.
- **Cơ chế**: Mở một cổng trong dải từ `30000-32767` trên toàn bộ các node. Lưu lượng gửi đến bất kỳ địa chỉ `<Node_IP>:<NodePort>` nào sẽ được tự động định tuyến đến Service và chuyển tiếp đến Pod thích hợp.

#### LoadBalancer
- **Mục đích**: Expose dịch vụ trực tiếp ra ngoài Internet thông qua bộ cân bằng tải của nhà cung cấp dịch vụ Cloud (ví dụ: AWS Network Load Balancer, GCP Cloud Load Balancing).
- **Cơ chế**: Tự động tạo một Load Balancer bên ngoài Cloud trỏ về NodePort của cụm. Phù hợp cho môi trường Production trên Cloud.

#### ExternalName
- **Mục đích**: Ánh xạ một Service trong Kubernetes với một DNS name bên ngoài cụm (ví dụ: một dịch vụ database RDS ngoài K8s).
- **Cơ chế**: Trả về một bản ghi CNAME của DNS mà không thực hiện proxy dữ liệu.

---

## 3. Probes — Cơ chế giám sát sức khỏe ứng dụng

Kubernetes sử dụng Probes (công cụ dò) để kiểm tra tình trạng của các container bên trong Pod. Điều này giúp hệ thống tự động khôi phục ứng dụng khi xảy ra lỗi. Có ba loại Probe hoạt động ở các giai đoạn khác nhau trong vòng đời của container:

| Đặc tính | Startup Probe | Liveness Probe | Readiness Probe |
| :--- | :--- | :--- | :--- |
| **Mục đích** | Kiểm tra xem ứng dụng bên trong container đã khởi động thành công hay chưa. | Kiểm tra xem container có đang hoạt động bình thường không, hay đã bị rơi vào trạng thái treo (deadlock). | Kiểm tra xem container đã sẵn sàng tiếp nhận lưu lượng mạng (traffic) chưa. |
| **Hành động khi thất bại** | Kubernetes sẽ hủy container và khởi động lại theo chính sách `restartPolicy`. | Kubernetes sẽ hủy container và khởi động lại để tự phục hồi. | Kubernetes sẽ ngắt kết nối IP của Pod khỏi Service, không gửi thêm traffic tới Pod đó nữa. |
| **Tần suất hoạt động** | Chỉ chạy khi container bắt đầu khởi động. Sẽ tắt ngay sau khi thành công lần đầu. | Chạy liên tục trong suốt vòng đời của container sau khi Startup Probe thành công. | Chạy liên tục trong suốt vòng đời của container sau khi Startup Probe thành công. |

### Các cơ chế kiểm tra (Check Mechanisms)
Các Probe có thể thực hiện kiểm tra qua ba phương thức:
1. **HTTPGet**: Gửi một yêu cầu HTTP GET đến một endpoint (ví dụ: `/healthz`). Thành công nếu mã phản hồi nằm trong khoảng `200-399`.
2. **TCPSocket**: Kiểm tra xem một cổng TCP cụ thể trên container có đang mở hay không.
3. **Exec**: Thực thi một câu lệnh cụ thể bên trong container. Thành công nếu câu lệnh trả về mã trạng thái bằng `0`.

### Cấu hình mẫu tối ưu cho một Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-health-check
spec:
  containers:
  - name: web-app
    image: nginx:alpine
    ports:
    - containerPort: 80
    
    # Dùng cho các ứng dụng cần nhiều thời gian để load cấu hình ban đầu
    startupProbe:
      httpGet:
        path: /healthz
        port: 80
      failureThreshold: 30
      periodSeconds: 10 # Cho phép tối đa 300 giây để khởi động
      
    # Đảm bảo khởi động lại Pod khi ứng dụng bị treo
    livenessProbe:
      httpGet:
        path: /healthz
        port: 80
      periodSeconds: 15
      timeoutSeconds: 2
      failureThreshold: 3
      
    # Đảm bảo chỉ gửi lưu lượng khi ứng dụng sẵn sàng xử lý yêu cầu
    readinessProbe:
      httpGet:
        path: /ready
        port: 80
      periodSeconds: 10
      timeoutSeconds: 2
      successThreshold: 1
      failureThreshold: 2
```
