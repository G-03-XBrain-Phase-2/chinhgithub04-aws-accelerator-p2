# Chuyên đề 01: Nền tảng K8s RBAC và Kiểm soát Quyền truy cập

## 1. Khái niệm cốt lõi của RBAC (Role-Based Access Control)
Kubernetes sử dụng cơ chế kiểm soát truy cập dựa trên vai trò (RBAC) để phân quyền cho người dùng (Users), tiến trình chạy trong Pod (ServiceAccounts) tác động vào các tài nguyên trong cụm.

RBAC được xây dựng trên 4 đối tượng tài nguyên chính:

### Role (Vai trò trong Namespace)
*   **Đặc điểm**: Chỉ có hiệu lực trong phạm vi một Namespace cụ thể.
*   **Công dụng**: Định nghĩa các quyền hành động (verbs như `get`, `list`, `watch`, `create`, `update`, `delete`) tác động lên các tài nguyên (resources như `pods`, `services`, `deployments`).
*   **Ví dụ**: Cho phép đọc danh sách Pod trong namespace `demo`.

### ClusterRole (Vai trò cấp Cụm)
*   **Đặc điểm**: Có hiệu lực trên toàn bộ cụm Kubernetes (Cluster-scoped).
*   **Công dụng**: Định nghĩa các quyền tương tự như Role, nhưng có thể áp dụng cho các tài nguyên không thuộc namespace (như `Node`, `PersistentVolume`, `Namespace`) hoặc áp dụng đồng loạt cho tất cả namespace.
*   **Ví dụ**: Cho phép liệt kê Node của cụm, hoặc cho phép xem Pods trên toàn bộ namespaces.

### RoleBinding (Liên kết Vai trò trong Namespace)
*   **Đặc điểm**: Ràng buộc một `Role` hoặc một `ClusterRole` với một đối tượng (Subject) trong phạm vi một Namespace cụ thể.
*   **Công dụng**: Cấp phát các quyền hạn được định nghĩa trong Role cho User, Group, hoặc ServiceAccount trong Namespace đó.

### ClusterRoleBinding (Liên kết Vai trò cấp Cụm)
*   **Đặc điểm**: Ràng buộc một `ClusterRole` với một đối tượng trên toàn cụm.
*   **Công dụng**: Cấp phát các quyền hạn cấp cụm cho đối tượng trên mọi Namespace và mọi tài nguyên phi Namespace.

---

## 2. ServiceAccount (Tài khoản Dịch vụ)
*   Trong khi User là định danh dành cho con người truy cập (thường xác thực qua Certificate hoặc OIDC), **ServiceAccount** là định danh được thiết kế cho các tiến trình/phần mềm chạy bên trong các Pod để giao tiếp an toàn với Kubernetes API Server.
*   Mỗi Namespace luôn có sẵn một ServiceAccount mặc định mang tên `default`. Khi triển khai các ứng dụng cần truy cập API (như Prometheus, ArgoCD, Controller), ta cần khởi tạo ServiceAccount riêng và phân quyền RBAC chặt chẽ cho nó.

---

## 3. Khai báo YAML chuẩn mẫu

### File: `developer-role.yaml`
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: demo
  name: developer-role
rules:
- apiGroups: [""] # "" đại diện cho core API group
  resources: ["pods", "services", "pods/log"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

### File: `developer-binding.yaml`
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-rolebinding
  namespace: demo
subjects:
- kind: ServiceAccount
  name: dev-service-account
  namespace: demo
roleRef:
  kind: Role
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
```

---

## 4. Công cụ kiểm tra quyền truy cập nhanh (`kubectl auth can-i`)
Kubernetes cung cấp lệnh `kubectl auth can-i` để quản trị viên kiểm tra nhanh xem một tài khoản có quyền thực hiện hành động cụ thể nào đó hay không.

### Các lệnh phổ biến:
*   **Tự kiểm tra quyền của bản thân**:
    ```bash
    kubectl auth can-i create pods
    kubectl auth can-i delete deployments --namespace=demo
    ```
*   **Đóng vai (Impersonate) một User khác để kiểm tra**:
    ```bash
    kubectl auth can-i list secrets --as=chinh-dev --namespace=demo
    ```
*   **Kiểm tra quyền của một ServiceAccount cụ thể**:
    ```bash
    kubectl auth can-i get configmaps --as=system:serviceaccount:demo:dev-service-account --namespace=demo
    ```
