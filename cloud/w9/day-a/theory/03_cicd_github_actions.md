# Chuyên đề 03: Tự động hóa CI/CD Hạ tầng với GitHub Actions

Áp dụng nguyên lý GitOps vào quản lý hạ tầng (Infrastructure as Code - IaC) đòi hỏi một quy trình tự động hóa nghiêm ngặt, đảm bảo mọi thay đổi trên mã nguồn Terraform đều được kiểm tra trước khi đưa vào môi trường Production. 

Quy trình này thường được hiện thực hóa qua hai mẫu thiết kế chính: **Plan-on-PR** và **Apply-on-Merge**.

---

## 1. Mẫu Thiết kế Plan-on-PR (Kiểm tra khi mở Pull Request)

### Mục tiêu
Khi một thành viên trong nhóm phát triển muốn thay đổi hạ tầng, họ sẽ tạo một nhánh (branch) mới và mở một Pull Request (PR) trỏ về nhánh `main`. Quy trình Plan-on-PR tự động kích hoạt để kiểm tra tính hợp lệ của mã nguồn mà không làm thay đổi hạ tầng thật.

### Các bước thực thi
1.  **Lắng nghe sự kiện**: Kích hoạt khi có sự kiện mở (opened) hoặc cập nhật (synchronize) một PR trỏ về nhánh `main`.
2.  **Kiểm tra cú pháp (Lint & Validate)**: Chạy `terraform fmt -check` và `terraform validate` để đảm bảo code viết đúng chuẩn cú pháp và logic cơ bản.
3.  **Lên kế hoạch thay đổi (Plan)**: Chạy lệnh `terraform plan` để sinh ra bản kế hoạch chi tiết về các tài nguyên sẽ bị thêm mới, sửa đổi hoặc xóa bỏ.
4.  **Báo cáo trực tiếp (Comment on PR)**: Trích xuất kết quả của lệnh `plan` và tự động bình luận (comment) trực tiếp vào giao diện PR. Điều này giúp người review (Reviewers) dễ dàng xem và đánh giá tác động trước khi nhấn nút Merge.

---

## 2. Mẫu Thiết kế Apply-on-Merge (Áp dụng khi Merge vào Main)

### Mục tiêu
Sau khi PR được phê duyệt và được merge (hợp nhất) vào nhánh `main`, quy trình Apply-on-Merge sẽ tự động kích hoạt để triển khai các thay đổi lên môi trường thực tế, đảm bảo Git chính là nguồn phản ánh đúng trạng thái thực của hạ tầng.

### Các bước thực thi
1.  **Lắng nghe sự kiện**: Kích hoạt khi có sự kiện push hoặc merge PR thành công vào nhánh `main`.
2.  **Khởi tạo (Init)**: Chạy `terraform init` để cấu hình backend và tải các provider.
3.  **Áp dụng thực tế (Apply)**: Chạy lệnh `terraform apply -auto-approve` để thực thi thay đổi một cách tự động mà không cần tương tác người dùng.

---

## 3. Ví dụ Cấu hình GitHub Actions Workflow Tiêu chuẩn

Dưới đây là một tệp cấu hình YAML của GitHub Actions (`.github/workflows/terraform.yml`) tích hợp cả hai quy trình trên:

```yaml
name: "Terraform GitOps Workflow"

on:
  pull_request:
    branches:
      - main
  push:
    branches:
      - main

permissions:
  contents: read
  pull-requests: write  # Quyền hạn để bot ghi bình luận lên PR

jobs:
  terraform:
    name: "Terraform Build"
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      TF_LOG: INFO

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform CLI
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.8.0

      - name: Terraform Format Check
        run: terraform fmt -check

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      # BƯỚC 1: Chạy Plan khi mở PR
      - name: Terraform Plan
        id: plan
        if: github.event_name == 'pull_request'
        run: terraform plan -no-color
        continue-on-error: true

      # BƯỚC 2: Viết comment kết quả Plan vào PR để Review
      - name: Post Plan Comment on PR
        uses: actions/github-script@v7
        if: github.event_name == 'pull_request'
        with:
          script: |
            const output = `#### Terraform Format and Style 🖌
            #### Terraform Initialization ⚙️
            #### Terraform Validation 🤖
            #### Terraform Plan 📖
            
            \`\`\`hcl
            ${process.env.PLAN}
            \`\`\`
            
            *Pusher: @${context.actor}, Action: \`${context.eventName}\`*`;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

      # BƯỚC 3: Chạy Apply khi code đã được merge vào main
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve
```
