# Chuyên đề 02: HCL Syntax Inside Out — Cú pháp, Kiểu dữ liệu và Cơ chế phân tích đồ thị

## 1. Ba Thành phần Cơ bản của Cú pháp HCL
Ngôn ngữ cấu hình HashiCorp (HCL) được thiết kế xoay quanh ba yếu tố cốt lõi: **Blocks**, **Arguments**, và **Expressions**.

```text
  ┌────────────────── BLOCK TYPE ──────────────────┐
  │                                                │
  resource "tls_private_key" "secure_key" {  ───┐  │
    algorithm = "RSA"  <─── ARGUMENT            │  │  <─── BLOCK
    rsa_bits  = 4096   <─── EXPRESSION (Literal)│  │
  }  ───────────────────────────────────────────┘  │
  └────────────────────────────────────────────────┘
```

### Blocks (Khối)
*   **Định nghĩa**: Là container chứa các thông tin cấu hình khác. Một block luôn bắt đầu bằng loại block (`Block Type`), theo sau là các nhãn (`Labels`) tùy thuộc vào loại block, và nội dung nằm trong cặp dấu ngoặc nhọn `{}`.
*   **Ví dụ về "The Big Three" block types**:
    *   `resource`: Khai báo tài nguyên muốn khởi tạo (e.g., `resource "aws_instance" "web" {}`).
    *   `variable`: Khai báo tham số đầu vào để tùy biến cấu hình (e.g., `variable "instance_count" {}`).
    *   `output`: Khai báo thông tin muốn xuất ra màn hình hoặc truyền cho module khác sau khi apply thành công (e.g., `output "ip_address" {}`).
*   **Các loại block khác**: `provider`, `terraform`, `data`, `locals`, `module`.

### Arguments (Đối số)
*   **Định nghĩa**: Gán một giá trị cho một tên tham số cụ thể nằm trong block. Arguments hoạt động như các cấu hình đầu vào (Inputs).
*   **Cú pháp**: `<argument_name> = <expression>` (luôn dùng dấu `=` để gán).

### Expressions (Biểu thức)
*   **Định nghĩa**: Đại diện cho một giá trị cụ thể, có thể là giá trị tĩnh (Literal value như `"RSA"`, `4096`, `true`) hoặc động thông qua các hàm, biến đổi logic, toán tử hay tham chiếu chuỗi (String Interpolation - e.g., `"${var.environment}-server"`).

---

## 2. Phân biệt Cực kỳ Quan trọng: Arguments vs Attributes

Trong Terraform, chúng ta rất dễ nhầm lẫn giữa hai khái niệm này, nhưng phân biệt chúng là điều kiện bắt buộc để viết mã nguồn chất lượng cao:

*   **Arguments (Đối số - Inputs)**:
    *   Là các tham số cấu hình được **chủ động viết vào code** để báo cho Terraform biết cách khởi tạo tài nguyên.
    *   Ví dụ: thuộc tính `algorithm` và `rsa_bits` của tài nguyên `tls_private_key` là các Arguments bắt buộc hoặc tùy chọn đầu vào.
*   **Attributes (Thuộc tính - Outputs)**:
    *   Là các thông tin được tài nguyên **xuất ra (export) sau khi được tạo lập thành công** ở runtime.
    *   Chúng ta không gán giá trị cho Attributes; thay vào đó, ta **tham chiếu** đến chúng để làm đầu vào cho các tài nguyên khác.
    *   Ví dụ: Tài nguyên `tls_private_key` sau khi được tạo sẽ export ra các attributes như `private_key_pem`, `public_key_openssh`. Tài nguyên khác (ví dụ: `local_file`) sẽ đọc giá trị này:
        ```hcl
        content = tls_private_key.secure_key.private_key_pem  # Tham chiếu đến Attribute
        ```

---

## 3. Hệ thống Kiểu Dữ liệu trong Terraform
HCL hỗ trợ hệ thống kiểu dữ liệu mạnh mẽ chia làm ba nhóm:

```text
HCL Data Types
├── Primitive Types (Kiểu nguyên bản)
│   ├── string  ("dev", "prod")
│   ├── number  (10, 3.14)
│   └── bool    (true, false)
│
├── Collection Types (Kiểu tập hợp - các phần tử cùng kiểu)
│   ├── list(...)  (Danh sách có thứ tự, lặp chỉ mục: [ "us-east-1a", "us-east-1b" ])
│   ├── map(...)   (Cặp Key-Value không thứ tự: { env = "dev", owner = "chinh" })
│   └── set(...)   (Tập hợp không thứ tự, các phần tử duy nhất, không trùng lặp)
│
└── Structural Types (Kiểu cấu trúc - các phần tử có thể khác kiểu)
    ├── object(...) (Định nghĩa chính xác schema các thuộc tính: name=string, port=number)
    └── tuple(...)  (Danh sách có số lượng phần tử cố định và kiểu khác nhau)
```

### Cách khai báo biến phức hợp mẫu (được dùng trong phần thực hành):
```hcl
variable "project_metadata" {
  type = object({
    project_name = string
    cost_center  = number
    tags         = list(string)
  })
}
```

---

## 4. Cơ chế Phân tích Đồ thị: Tại sao Thứ tự Tệp tin không quan trọng?

Trong nhiều ngôn ngữ lập trình tuyến tính (như Bash, Python), mã nguồn được biên dịch và chạy từ trên xuống dưới, từ tệp này qua tệp khác theo thứ tự import. Nhưng trong Terraform:

> **"File order doesn't matter — Thứ tự dòng code hay thứ tự tệp tin hoàn toàn không ảnh hưởng đến kết quả triển khai."**

### Nguyên lý hoạt động:
1.  **Gộp tệp tin (Merging)**: Khi chạy bất kỳ lệnh nào, Terraform tự động gộp toàn bộ các tệp tin có đuôi `.tf` trong thư mục hiện hành thành một khối cấu hình duy nhất.
2.  **Đồ thị phụ thuộc (Directed Acyclic Graph - DAG)**: Thay vì chạy tuyến tính, Terraform phân tích các liên kết tham chiếu giữa các tài nguyên (ví dụ: Tài nguyên B sử dụng một attribute của Tài nguyên A). Từ đó, Terraform xây dựng một **Đồ thị có hướng không chu trình (DAG)** để xác định thứ tự triển khai logic:
    *   Tài nguyên nào không phụ thuộc vào ai sẽ được tạo song song cùng lúc (Parallelization) để tăng tốc độ.
    *   Tài nguyên nào phụ thuộc sẽ phải chờ tài nguyên gốc tạo xong.
3.  **Dependency Khai báo (Implicit vs Explicit)**:
    *   **Implicit Dependency (Phụ thuộc ngầm định)**: Xảy ra tự động khi ta tham chiếu thuộc tính tài nguyên này vào đối số tài nguyên kia (e.g., `content = tls_private_key.secure_key.private_key_pem`). Terraform tự hiểu phải tạo `tls_private_key` trước.
    *   **Explicit Dependency (Phụ thuộc tường minh)**: Khai báo thủ công bằng đối số `depends_on = [resource_type.name]` khi hai tài nguyên có quan hệ phụ thuộc ngầm nhưng không trực tiếp tham chiếu giá trị của nhau trong code.
