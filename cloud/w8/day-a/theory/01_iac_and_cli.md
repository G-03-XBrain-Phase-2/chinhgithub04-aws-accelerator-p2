# Chuyên đề 01: Infrastructure as Code & Terraform CLI Core Workflow

## 1. Triết lý Infrastructure as Code (IaC)

### Vấn đề của phương pháp truyền thống (ClickOps)
Trước khi IaC xuất hiện, việc triển khai hạ tầng được thực hiện thủ công thông qua giao diện Web UI (AWS Console, Azure Portal) hoặc chạy script đơn lẻ. Cách tiếp cận "ClickOps" này dẫn đến nhiều vấn đề nghiêm trọng trong môi trường doanh nghiệp:
*   **Không nhất quán (Configuration Drift)**: Rất khó để tái cấu trúc chính xác các môi trường (Dev, Staging, Production) giống hệt nhau khi thực hiện thủ công.
*   **Thiếu lịch sử thay đổi (No Auditing)**: Không có cách nào biết được ai đã sửa cấu hình gì, vào lúc nào và tại sao.
*   **Khả năng mở rộng kém (Poor Scalability)**: Nhân rộng hệ thống lên hàng chục khu vực (Regions) khác nhau trở thành cơn ác mộng về nguồn lực.
*   **Lỗi con người (Human Error)**: Chỉ cần một cú click chuột sai hoặc quên cấu hình một tham số bảo mật cũng có thể làm sập hệ thống hoặc rò rỉ dữ liệu.

### Giải pháp IaC và Hai trường phái Tiếp cận
IaC giải quyết triệt để các vấn đề trên bằng cách định nghĩa toàn bộ hạ tầng phần cứng, mạng, bảo mật dưới dạng các tệp tin cấu hình có thể đọc được bằng cả con người và máy tính. Có hai trường phái thiết kế IaC:

| Đặc tính | Imperative (Mệnh lệnh - e.g., Ansible, Bash Scripts) | Declarative (Khai báo - e.g., Terraform, CloudFormation) |
| :--- | :--- | :--- |
| **Cách tiếp cận** | Định nghĩa **cách thức thực hiện** (Quy trình từng bước). | Định nghĩa **trạng thái mong muốn cuối cùng**. |
| **Idempotency** | Phải tự xử lý thủ công trong code để tránh chạy lại tạo trùng lặp. | Tự động xử lý bởi Engine của công cụ dựa trên State. |
| **Quản lý tài nguyên** | Khó theo dõi và tự động xóa tài nguyên không còn dùng. | Tự động xác định tài nguyên thừa và xóa bỏ khi code thay đổi. |
| **Ví dụ** | "Hãy tạo 1 EC2, sau đó mở cổng 80, sau đó cài nginx." | "Tôi muốn có 1 EC2 với nginx đang mở cổng 80." |

---

## 2. Giới thiệu về Terraform
Phát triển bởi HashiCorp, **Terraform** là một công cụ IaC mã nguồn mở tiêu biểu cho trường phái **Declarative**.
*   **Độc lập Cloud (Cloud-agnostic)**: Một công cụ duy nhất quản lý được AWS, GCP, Azure, Kubernetes, SaaS, v.v. thông qua hệ thống **Providers** phong phú.
*   **Cơ chế hoạt động**: Terraform đọc tệp cấu hình HCL, xây dựng một đồ thị phụ thuộc (Graph), so sánh với trạng thái thực tế (State), sau đó gọi API của Cloud Providers để đồng bộ hóa hạ tầng về trạng thái mong muốn.

---

## 3. Terraform CLI Core Workflow Deep Dive

Quy trình làm việc chuẩn của Terraform xoay quanh bốn lệnh cốt lõi. Hiểu sâu cơ chế hoạt động thực tế (under the hood) của từng lệnh là chìa khóa để vận hành hạ tầng chuyên nghiệp:

```text
[ Viết Code HCL .tf ]
        │
        ▼
[ terraform init ]    ──► (Tải & cài đặt Providers/Plugins)
        │
        ▼
[ terraform plan ]    ──► (Lên kế hoạch thay đổi hạ tầng)
        │
        ▼
[ terraform apply ]   ──► (Áp dụng thực tế & ghi nhận vào State)
        │
        ▼
[ terraform destroy ] ──► (Hủy toàn bộ tài nguyên khi cần)
```


### 1️⃣ `terraform init`
*   **Hành vi**: Khởi tạo thư mục làm việc. Đây là lệnh đầu tiên phải chạy sau khi viết code mới hoặc clone dự án từ Git.
*   **Under the hood**:
    *   Phân tích code cấu hình để xác định các provider cần thiết (ví dụ: `hashicorp/aws` hoặc `hashicorp/local`).
    *   Tải plugin provider tương ứng từ Terraform Registry về lưu tại thư mục ẩn `.terraform/`.
    *   Tạo file `.terraform.lock.hcl` (Dependency Lock File) để cố định phiên bản (version) chính xác của provider, đảm bảo tính nhất quán giữa các máy chạy khác nhau.

### 2️⃣ `terraform plan`
*   **Hành vi**: So sánh cấu hình hiện tại trong code với trạng thái thực tế (State) để đưa ra kế hoạch hành động. Đây là chế độ **dry-run** (chỉ đọc), không thay đổi hạ tầng thật.
*   **Ý nghĩa các ký hiệu trong kế hoạch**:
    *   `+ create`: Tạo tài nguyên mới hoàn toàn.
    *   `~ update in-place`: Thay đổi một số thuộc tính của tài nguyên hiện có mà không cần hủy đi tạo lại (ví dụ: thay đổi tags).
    *   `- destroy`: Xóa bỏ tài nguyên (do bị xóa khỏi cấu hình hoặc không còn được khai báo).
    *   `-/+ replace`: Hủy tài nguyên cũ và tạo tài nguyên mới thay thế (xảy ra khi thay đổi một thuộc tính bắt buộc phải tạo mới, ví dụ: thay đổi AMI của EC2 hoặc ID mạng con).

### 3️⃣ `terraform apply`
*   **Hành vi**: Áp dụng các thay đổi để đưa hạ tầng thật về khớp với cấu hình trong code.
*   **Under the hood**:
    *   Tự động chạy lại `plan` và yêu cầu xác nhận của người dùng (`yes`).
    *   Gọi các hàm API tương ứng của nhà cung cấp dịch vụ để thực hiện thao tác.
    *   Ghi nhận toàn bộ thông tin tài nguyên được tạo ra (bao gồm các giá trị chỉ xuất hiện ở runtime như ID, IP công cộng) vào tệp lưu trữ trạng thái `terraform.tfstate`.

### 4️⃣ `terraform destroy`
*   **Hành vi**: Hủy bỏ toàn bộ hạ tầng được quản lý bởi cấu hình Terraform hiện tại.
*   **Under the hood**:
    *   Đọc tệp `terraform.tfstate` để xác định danh sách các tài nguyên đã tạo.
    *   Tính toán thứ tự hủy bỏ tối ưu dựa trên quan hệ phụ thuộc ngược (hủy tài nguyên phụ thuộc trước, tài nguyên gốc sau).
    *   Yêu cầu người dùng xác nhận (`yes`) trước khi xóa thực tế.
