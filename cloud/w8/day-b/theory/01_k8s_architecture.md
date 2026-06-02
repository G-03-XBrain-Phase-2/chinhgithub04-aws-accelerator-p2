# Chuyên đề 01: Kiến trúc tổng quan Kubernetes

Kubernetes (K8s) là một hệ thống mã nguồn mở dùng để tự động hóa việc triển khai, mở rộng và quản lý các ứng dụng dưới dạng container. Để vận hành hệ thống một cách hiệu quả, ta cần hiểu rõ kiến trúc phân rã thành hai phân vùng chính: **Control Plane** (Phân hệ điều khiển) và **Worker Node** (Phân hệ thực thi).

---

## 1. Thành phần của Control Plane (Master Node)

Control Plane đóng vai trò là bộ não của cụm (cluster), chịu trách nhiệm đưa ra các quyết định toàn cục (ví dụ: lên lịch chạy ứng dụng), phát hiện và phản hồi các sự kiện trong cụm.

```text
+-----------------------------------------------------------+
|                      CONTROL PLANE                        |
|                                                           |
|  +------------+     +----------------+     +-----------+  |
|  | Scheduler  |     |   API Server   |     |Controller |  |
|  +-----+------+     +-------+--------+     |  Manager  |  |
|        |                    |              +-----+-----+  |
|        +---------+----------+                    |        |
|                  |                               |        |
|            +-----+-----+                         |        |
|            |   etcd    | <-----------------------+        |
|            +-----------+                                  |
+-----------------------------------------------------------+
```

### Kube-apiserver
- **Chức năng**: Là cổng vào duy nhất của Control Plane, cung cấp giao tiếp qua HTTP/REST API. Tất cả các tương tác nội bộ và ngoại vi (từ người dùng qua `kubectl`, từ các node qua `kubelet`) đều phải đi qua API Server.
- **Cơ chế**: Tiếp nhận yêu cầu, thực hiện xác thực (Authentication), phân quyền (Authorization), kiểm tra tính hợp lệ của dữ liệu (Admission Control) trước khi ghi dữ liệu vào cơ sở dữ liệu của hệ thống.

### Etcd
- **Chức năng**: Là cơ sở dữ liệu lưu trữ dưới dạng key-value, có tính nhất quán và tính sẵn sàng cao (highly-available).
- **Vai trò**: Etcd lưu trữ toàn bộ trạng thái cấu hình và trạng thái thực tế của hệ thống Kubernetes. Đây là nguồn chân lý duy nhất (Single Source of Truth) của cả cụm. Không có thành phần nào ngoài API Server được phép đọc hoặc ghi trực tiếp vào etcd.

### Kube-scheduler
- **Chức năng**: Chịu trách nhiệm phát hiện các Pod mới được tạo nhưng chưa được phân bổ vào node nào, sau đó chọn một Worker Node phù hợp nhất để chạy Pod đó.
- **Tiêu chí quyết định**: Quá trình lập lịch gồm hai bước chính:
  1. **Filtering (Lọc)**: Tìm các node đáp ứng đủ yêu cầu tài nguyên (CPU, RAM), các ràng buộc về vị trí (nodeSelector, affinity, taints/tolerations).
  2. **Scoring (Chấm điểm)**: Đánh giá và xếp hạng các node đủ điều kiện theo các thuật toán tối ưu hóa hiệu năng và mật độ phân bổ tài nguyên để chọn ra node tốt nhất.

### Kube-controller-manager
- **Chức năng**: Chạy các tiến trình điều khiển (controllers) để duy trì trạng thái mong muốn của cụm. Mỗi controller là một vòng lặp kiểm soát vô tận liên tục so sánh trạng thái mong muốn (định nghĩa trong code cấu hình) với trạng thái thực tế.
- **Các controller tiêu biểu**:
  - *Node Controller*: Giám sát sức khỏe của các node.
  - *Job Controller*: Giám sát các task chạy một lần rồi dừng.
  - *EndpointSlice Controller*: Kết nối giữa Pod và Service.

---

## 2. Thành phần của Worker Node

Worker Node là các máy ảo hoặc máy vật lý chạy các ứng dụng thực tế dưới dạng container. Mỗi node được Control Plane quản lý và chứa các dịch vụ cần thiết để vận hành Pod.

```text
+-----------------------------------------------------------+
|                       WORKER NODE                         |
|                                                           |
|  +--------------------+             +------------------+  |
|  |      Kubelet       |             |    Kube-proxy    |  |
|  +---------+----------+             +--------+---------+  |
|            |                                 |            |
|            ▼ (CRI)                           ▼            |
|  +--------------------+             +------------------+  |
|  | Container Runtime  |             | iptables / IPVS  |  |
|  | (containerd)       |             | (Traffic routing)|  |
|  +--------------------+             +------------------+  |
+-----------------------------------------------------------+
```

### Kubelet
- **Chức năng**: Là một agent chạy trên từng Worker Node của cụm. Nhiệm vụ chính của kubelet là đảm bảo các container được khai báo trong PodSpec đang hoạt động bình thường và khỏe mạnh.
- **Cơ chế**: Nhận chỉ thị từ API Server, giao tiếp với Container Runtime thông qua Container Runtime Interface (CRI) để khởi động hoặc dừng các container tương ứng, sau đó báo cáo trạng thái của Node và các Pod về Control Plane.

### Kube-proxy
- **Chức năng**: Là một dịch vụ mạng chạy trên mỗi node, duy trì các quy tắc mạng (network rules) trên host.
- **Cơ chế**: Thực hiện chuyển hướng lưu lượng mạng (traffic redirection) để định tuyến các kết nối đến đúng Pod đích. Kube-proxy thường cấu hình bảng định tuyến IP (iptables) hoặc IPVS trên node để xử lý lưu lượng mạng phân phối đến các Service.

### Container Runtime
- **Chức năng**: Là phần mềm chịu trách nhiệm trực tiếp trong việc vận hành các container.
- **Các loại được hỗ trợ**: Kubernetes tương thích với các runtime tuân thủ chuẩn CRI, phổ biến nhất hiện nay là `containerd` và `CRI-O`.

---

## 3. Luồng khởi tạo tài nguyên Pod trong hệ thống

Để hình dung sự phối hợp nhịp nhàng giữa các thành phần trên, chúng ta cùng xem xét luồng xử lý khi thực thi lệnh khởi tạo một Pod (`kubectl apply -f pod.yaml`):

```text
[Người dùng]
     │ (kubectl apply)
     ▼
[API Server] ──► (1. Xác thực, phân quyền & lưu trạng thái Pending vào etcd)
     │
     ▼ (Watch event)
[Scheduler]  ──► (2. Phát hiện Pod mới, tính toán và chọn Node X phù hợp)
     │
     ▼ (Ghi nhận gán node)
[API Server] ──► (3. Lưu thông tin phân bổ Node X vào etcd)
     │
     ▼ (Watch event)
[Kubelet Node X] ──► (4. Phát hiện Pod được gán cho mình, gọi CRI khởi tạo)
     │
     ▼ (CRI call)
[Container Runtime] ──► (5. Kéo image và chạy container thực tế)
     │
     ▼ (Báo cáo sức khỏe)
[Kubelet Node X] ──► (6. Cập nhật trạng thái Running lên API Server để lưu vào etcd)
```
