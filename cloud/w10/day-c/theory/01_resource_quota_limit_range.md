# Chuyên đề 01: Quản lý Định mức Tài nguyên (ResourceQuota & LimitRange)

## 1. ResourceQuota (Định mức tài nguyên cấp Namespace)

### Khái niệm & Vai trò
*   **ResourceQuota** là tài nguyên quản trị giúp giới hạn tổng lượng tài nguyên mà tất cả các Pod chạy trong một Namespace cụ thể được phép tiêu thụ.
*   **Mục đích**:
    *   **Ngăn chặn hiện tượng Noisy Neighbor**: Một ứng dụng hoặc đội phát triển vô tình scale số lượng Pod quá lớn hoặc rò rỉ bộ nhớ, chiếm dụng toàn bộ tài nguyên CPU/RAM của Worker Node và làm gián đoạn các namespace khác chạy chung cụm.
    *   **Quản lý chi phí**: Giới hạn kích thước tối đa của từng môi trường (Dev, Staging) để tối ưu hóa chi phí hạ tầng.
*   **Hành vi**: Nếu tổng tài nguyên yêu cầu (requests) hoặc giới hạn (limits) vượt quá ngưỡng ResourceQuota, API Server sẽ từ chối tạo Pod mới.

### YAML mẫu: `namespace-resource-quota.yaml`
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
  namespace: payments
spec:
  hard:
    pods: "10"                   # Tối đa 10 Pod được chạy đồng thời
    services: "5"                 # Tối đa 5 Services được tạo
    requests.cpu: "2"             # Tổng CPU Request của các Pod <= 2 Core
    requests.memory: "2Gi"        # Tổng Memory Request của các Pod <= 2 GiB
    limits.cpu: "4"               # Tổng CPU Limit của các Pod <= 4 Core
    limits.memory: "4Gi"          # Tổng Memory Limit của các Pod <= 4 GiB
```

---

## 2. LimitRange (Giới hạn tài nguyên cấp Container)

### Khái niệm & Vai trò
*   **LimitRange** thiết lập các ràng buộc về tài nguyên CPU và Memory ở mức **từng Container đơn lẻ** (hoặc Pod, PersistentVolumeClaim) trong một Namespace.
*   **Mục đích**:
    *   **Inject giá trị mặc định**: Nếu nhà phát triển viết tệp YAML Deployment mà không khai báo tài nguyên (requests/limits), LimitRange sẽ tự động điền các giá trị mặc định được định cấu hình sẵn. Điều này cực kỳ quan trọng để đảm bảo tất cả Pod chạy trong cụm đều có định mức tài nguyên rõ ràng (tránh bị OPA Gatekeeper hoặc các chính sách an toàn chặn lại).
    *   **Ràng buộc ngưỡng (Min/Max)**: Đảm bảo không có Container nào khai báo tài nguyên quá nhỏ (gây nghẽn) hoặc quá lớn (gây lãng phí).

### YAML mẫu: `container-limit-range.yaml`
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: container-limit-range
  namespace: payments
spec:
  limits:
  - default:                     # Giá trị Limits mặc định nếu container không khai báo
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:              # Giá trị Requests mặc định nếu container không khai báo
      cpu: "100m"
      memory: "256Mi"
    max:                         # Ngưỡng Limits tối đa container được phép khai báo
      cpu: "1"
      memory: "1Gi"
    min:                         # Ngưỡng Requests tối thiểu container phải khai báo
      cpu: "50m"
      memory: "64Mi"
    type: Container              # Áp dụng ở mức Container
```

---

## 3. Mối quan hệ giữa ResourceQuota và LimitRange
*   **Tương quan**: ResourceQuota hoạt động ở mức vĩ mô (tổng tài nguyên của cả Namespace), trong khi LimitRange hoạt động ở mức vi mô (từng Container trong namespace đó).
*   **Ràng buộc bắt buộc**: Khi một Namespace đã cấu hình ResourceQuota, **mọi Pod/Container** tạo mới trong namespace đó bắt buộc phải khai báo đầy đủ `resources.requests` và `resources.limits`. Nếu không khai báo và namespace đó cũng không có LimitRange để inject giá trị mặc định, API Server sẽ từ chối khởi tạo Pod ngay lập tức.
