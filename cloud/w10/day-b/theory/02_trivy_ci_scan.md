# Chuyên đề 02: Quét lỗ hổng bảo mật ảnh Container (Trivy Scan trong CI)

## 1. Tầm quan trọng của việc quét ảnh trong CI/CD
*   **Nguy cơ từ Base Image và thư viện bên thứ ba**: Container image thường chứa hệ điều hành tối giản (base image) và hàng loạt thư viện ứng dụng phụ thuộc. Các thành phần này liên tục phát sinh các lỗ hổng bảo mật mới (Common Vulnerabilities and Exposures - CVE).
*   **Quét sớm (Shift-Left Security)**: Thực hiện quét lỗ hổng bảo mật ngay tại bước xây dựng ảnh trong CI pipeline giúp phát hiện và ngăn chặn lỗ hổng từ sớm, trước khi ảnh được đẩy lên Container Registry hoặc deploy vào cụm Kubernetes.

---

## 2. Công cụ quét lỗ hổng Trivy
**Trivy** (phát triển bởi Aqua Security) là một công cụ quét bảo mật đa năng, nhanh chóng và dễ sử dụng. Trivy hỗ trợ quét:
*   Mã nguồn ứng dụng (Dependencies).
*   File cấu hình IaC (Terraform, Kubernetes YAML, Dockerfile) để phát hiện cấu hình sai (misconfigurations).
*   Ảnh container (Container Images) để phát hiện lỗ hổng hệ điều hành và thư viện.

---

## 3. Chính sách Ngăn chặn lỗi (Fail-on Policy) trong CI
Để đảm bảo không có ảnh lỗi nào được đưa lên môi trường chạy, CI pipeline cần được cấu hình để tự động báo đỏ và dừng chạy nếu ảnh container vi phạm chính sách bảo mật:
*   **Exit Code**: Cấu hình Trivy trả về mã thoát khác 0 (thường là `exit-code: 1`) khi phát hiện lỗ hổng. Mặc định Trivy chỉ in ra báo cáo và trả về `exit-code: 0` (CI vẫn xanh).
*   **Ngưỡng nghiêm trọng (Severity)**: Thiết lập bộ lọc chỉ chặn đứng pipeline đối với các lỗ hổng ở mức độ **HIGH** hoặc **CRITICAL**, tránh làm gián đoạn luồng CI vì các lỗi nhỏ (LOW, MEDIUM) chưa có giải pháp vá.

---

## 4. Quản lý Ngoại lệ bằng `.trivyignore`
Trong thực tế, có những lỗ hổng chưa có bản vá từ nhà phát triển thư viện (unfixed CVEs), hoặc lỗ hổng đó không thể khai thác được trong ngữ cảnh chạy của ứng dụng. Để không làm nghẽn pipeline, ta sử dụng cơ chế bỏ qua lỗ hổng:

*   **Tệp tin `.trivyignore`**: Đặt ở thư mục gốc của dự án. Chứa danh sách các mã CVE cần bỏ qua kèm theo comment giải thích lý do cụ thể.
*   **Quy trình phê duyệt (Security Exemption Process)**:
    1.  Nhóm phát triển đề xuất ngoại lệ kèm phân tích rủi ro.
    2.  Đội ngũ bảo mật đánh giá phê duyệt và quy định thời hạn hiệu lực của ngoại lệ (ví dụ: tối đa 30 ngày phải rà soát lại).
    3.  Thêm mã CVE vào `.trivyignore`.

---

## 5. Cấu hình GitHub Actions mẫu tích hợp Trivy

```yaml
name: Build and Security Scan

on:
  push:
    branches: [ main ]

jobs:
  build-and-scan:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Build Docker Image
      run: |
        docker build -t my-app:test .

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: 'my-app:test'
        format: 'table'
        exit-code: '1' # Báo đỏ pipeline nếu vi phạm
        ignore-unfixed: true # Bỏ qua các CVE chưa có bản vá chính thức từ upstream
        vuln-type: 'os,library'
        severity: 'CRITICAL,HIGH' # Chỉ chặn khi phát hiện lỗi HIGH hoặc CRITICAL
```
