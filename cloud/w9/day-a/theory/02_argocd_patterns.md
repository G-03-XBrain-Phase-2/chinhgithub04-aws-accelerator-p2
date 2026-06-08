# Chuyên đề 02: Các Mẫu Thiết kế Nâng cao trong ArgoCD

Để quản lý hệ thống phân tán lớn và có nhiều tài nguyên phụ thuộc lẫn nhau, ArgoCD cung cấp các cơ chế nâng cao giúp điều phối luồng deployment một cách tuần tự và tự động hóa cao.

## 1. Mô hình App-of-Apps (Ứng dụng của các Ứng dụng)

### Vấn đề của phương pháp quản lý thủ công
Khi số lượng dịch vụ (microservices) tăng lên, việc vào giao diện ArgoCD Web UI để tạo thủ công từng tài nguyên `Application` (định nghĩa Git Repo nguồn, nhánh đồng bộ, cụm đích và namespace) trở nên kém hiệu quả và dễ sai sót.

### Khái niệm App-of-Apps
App-of-Apps là một design pattern trong đó chúng ta chỉ cần khai báo một tài nguyên ArgoCD Application duy nhất làm gốc (Root Application). 
*   Root Application này không trỏ tới các manifest ứng dụng trực tiếp, mà trỏ tới một thư mục trong Git chứa các khai báo tài nguyên `Application` của các ứng dụng con (Child Applications).
*   Khi Root Application thực hiện đồng bộ (Sync), nó sẽ quét thư mục đó và tự động tạo ra các Child Applications tương ứng trên cụm.

```text
                  [ ArgoCD Engine ]
                          │
                          ▼ (Sync)
                [ Root Application ]
                          │
         ┌────────────────┼────────────────┐
         ▼ (Create)       ▼ (Create)       ▼ (Create)
    [ Child App 1 ]  [ Child App 2 ]  [ Child App 3 ]
     (Database)       (Backend API)     (Frontend)
         │                │                │
         ▼ (Deploy)       ▼ (Deploy)       ▼ (Deploy)
     [ K8s DB ]       [ K8s BE ]       [ K8s FE ]
```

### Ví dụ cấu hình Manifest của Root Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/example/gitops-monorepo.git'
    targetRevision: HEAD
    path: argocd-apps  # Thư mục chứa các manifest YAML của Child Applications
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 2. Cơ chế Điều phối Thứ tự: Sync Waves

Mặc định, khi đồng bộ, ArgoCD sẽ gửi tất cả tài nguyên trong thư mục Git lên cụm Kubernetes cùng một lúc. Tuy nhiên, nhiều trường hợp chúng ta cần một thứ tự cụ thể (ví dụ: tạo Namespace trước, tạo ConfigMap/Secret rồi mới tạo Deployment).

ArgoCD giải quyết bài toán này bằng cơ chế **Sync Waves**.

### Cách hoạt động
*   Mỗi tài nguyên K8s có thể được gắn một nhãn annotation chỉ định số thứ tự wave của nó.
*   ArgoCD sẽ đồng bộ tài nguyên theo thứ tự tăng dần của chỉ số wave (từ số âm nhỏ nhất đến số dương lớn nhất).
*   Mỗi wave chỉ được thực hiện khi wave trước đó đã chuyển sang trạng thái khỏe mạnh (Healthy).

### Cấu hình annotation
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "5"  # Chỉ số wave có thể âm hoặc dương, mặc định là "0"
```

### Ví dụ phân bổ thứ tự wave tiêu chuẩn
1.  **Wave -5**: Khởi tạo Namespace, Custom Resource Definitions (CRDs).
2.  **Wave -2**: Cấu hình cơ sở hạ tầng nền tảng (Secrets, ConfigMaps, ServiceAccounts).
3.  **Wave 0**: Khởi chạy các dịch vụ lưu trữ hoặc cơ sở dữ liệu (StatefulSets, Databases).
4.  **Wave 2**: Triển khai các ứng dụng API chính (Deployments).
5.  **Wave 5**: Thiết lập định tuyến và tường lửa (Services, Ingresses, NetworkPolicies).

---

## 3. Tự động hóa Vòng đời: Sync Hooks

Bên cạnh thứ tự đồng bộ tài nguyên tĩnh, chúng ta thường cần thực hiện các tác vụ động tại các thời điểm cụ thể trong vòng đời đồng bộ (ví dụ: chạy database migration trước khi nâng cấp phiên bản app, hoặc gửi thông báo Slack sau khi hoàn thành deploy).

ArgoCD cung cấp tính năng **Sync Hooks** để giải quyết nhu cầu này thông qua các K8s Jobs hoặc Pods.

### Các loại Hook phổ biến

| Tên Hook | Thời điểm thực thi | Ứng dụng thực tế |
| :--- | :--- | :--- |
| **PreSync** | Chạy trước khi bất kỳ tài nguyên nào được đồng bộ hoặc thay đổi. | Thực hiện backup database hiện tại; chạy migration schema cơ sở dữ liệu. |
| **PostSync** | Chạy sau khi tất cả tài nguyên đã được đồng bộ thành công và chuyển sang trạng thái Healthy. | Gửi webhook báo cáo trạng thái lên Slack/Teams; chạy test kiểm thử tích hợp (integration tests). |
| **SyncFail** | Chỉ chạy khi tiến trình đồng bộ hoặc kiểm thử của wave bị thất bại. | Chạy script rollback dữ liệu khẩn cấp; gửi cảnh báo độ ưu tiên cao về kênh SRE. |
| **Skip** | Bỏ qua không đồng bộ tài nguyên này trong tiến trình sync hiện tại. | Các tài nguyên chỉ dùng để debug cục bộ. |

### Cấu hình annotation cho Hook
Để chỉ định một tài nguyên làm Hook, chúng ta khai báo nhãn annotation tương ứng. Đồng thời, nên đi kèm chính sách xóa Hook (Hook Delete Policy) để dọn dẹp các Job Pods thừa sau khi chạy xong.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: schema-migration-job
  annotations:
    argocd.argoproj.io/hook: PreSync  # Định nghĩa thời điểm chạy
    argocd.argoproj.io/hook-delete-policy: HookSucceeded  # Xóa Pod tự động sau khi chạy thành công
spec:
  template:
    spec:
      containers:
      - name: db-migrator
        image: python:alpine
        command: ["python", "manage.py", "db", "upgrade"]
      restartPolicy: Never
```
