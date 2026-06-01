# W8-D1: Nhật ký Tự học — Nền tảng Terraform

Tài liệu này lưu trữ toàn bộ nội dung học tập và thực hành trong Ngày 1 (Tuần 8).

---

## Cấu trúc thư mục mô-đun

```text
cloud/w8/day-a/
├── theory/                   # Chuyên đề lý thuyết chuyên sâu
│   ├── 01_iac_and_cli.md     # Triết lý IaC, vấn đề ClickOps & luồng hoạt động CLI
│   ├── 02_hcl_syntax.md      # Cú pháp HCL, biến phức hợp & cơ chế đồ thị DAG
│   └── 03_state_and_drift.md # Bản chất State, lệch cấu hình & ép buộc tái tạo tài nguyên
└── practice/                 # Môi trường thực hành cấu trúc đa tệp tin
    ├── main.tf               # Định nghĩa tài nguyên và mối quan hệ phụ thuộc
    ├── variables.tf          # Khai báo các biến đầu vào kiểu phức tạp
    ├── providers.tf          # Cấu hình độc lập cho các Provider Plugins
    ├── outputs.tf            # Định nghĩa kết quả xuất động ở runtime
    ├── .terraform.lock.hcl   # Tệp khóa cố định phiên bản Provider Plugins
    └── README.md             # Hướng dẫn chi tiết quy trình chạy, thử nghiệm Drift & Replace
```

---

## Điểm nhấn của các phân khu

### [1. Lý thuyết](theory/)
Khu vực này lưu trữ các ghi chép nghiên cứu sâu sắc về cơ chế vận hành bên dưới của Terraform:
*   **[Chuyên đề 01: Triết lý IaC & Workflow của CLI](theory/01_iac_and_cli.md)**: Tìm hiểu sâu về mô hình mệnh lệnh vs khai báo, hiểm họa ClickOps, ý nghĩa các ký hiệu thay đổi trong plan và chi tiết vòng đời các lệnh CLI.
*   **[Chuyên đề 02: Phân tích Cú pháp HCL toàn diện](theory/02_hcl_syntax.md)**: Phân biệt cấu trúc khối (Blocks), đối số (Arguments) vs thuộc tính xuất runtime (Attributes), ứng dụng hệ thống kiểu dữ liệu phức tạp và cơ chế xây dựng đồ thị phụ thuộc DAG.
*   **[Chuyên đề 03: Cơ chế hoạt động của State & Drift](theory/03_state_and_drift.md)**: Giải mã vai trò của State, cách phát hiện và khắc phục lệch cấu hình (Drift) thực tế, cơ chế đánh dấu vấy bẩn và ép buộc tái tạo tài nguyên an toàn.

### [2. Thực hành](practice/)
Môi trường sandbox thực thi đa tệp tin an toàn giúp tự tay thử nghiệm các tính năng nâng cao:
*   **Kiểu dữ liệu nâng cao**: Áp dụng cấu trúc `object` phức tạp có kiểm tra kiểu dữ liệu tĩnh.
*   **Tham chiếu thuộc tính**: Kết nối thuộc tính runtime của tài nguyên mật mã làm đối số cho tệp cục bộ.
*   **Thử nghiệm Drift**: Hướng dẫn chi tiết các bước sửa đổi thủ công tài nguyên bên ngoài để Terraform phát hiện lệch cấu hình và tự động khôi phục.
*   **Tái tạo cưỡng bức**: Thực hành ép buộc tái tạo tài nguyên sạch sẽ bằng tham số `-replace` hiện đại.

---

## Bằng chứng đối chiếu và Phản hồi
*   Để xem toàn bộ tóm tắt quá trình tự học và phản hồi học tập chi tiết của ngày hôm nay (Thứ Hai, 01/06/2026), vui lòng kiểm tra: **[reflection.md](../reflection.md)**.
