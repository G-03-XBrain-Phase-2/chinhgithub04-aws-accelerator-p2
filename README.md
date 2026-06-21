# AWS Accelerator — Phase 2 Portfolio

*   **Họ và tên:** Nguyễn Đức Chinh
*   **ID:** XB-DN26-080
*   **Group:** 3
*   **Chuyên ngành:** Cloud / DevOps

---

## Lộ trình & Theo dõi Tiến độ

Bảng dưới đây tổng hợp lộ trình học tập và trạng thái hoàn thành các nội dung trong Phase 2:

| Tuần | Ngày / Chuyên đề | Trạng thái | Nội dung trọng tâm / Sản phẩm | Liên kết |
| :--- | :--- | :---: | :--- | :---: |
| **W8** | **Day A: Terraform Basics** | ![Hoàn thành](https://img.shields.io/badge/Hoàn_thành-brightgreen) | Tìm hiểu IaC, cú pháp HCL, luồng CLI (Init/Plan/Apply/Destroy), thực hành phát hiện Drift và Replace tài nguyên | [Xem chi tiết](cloud/w8/day-a/README.md) |
| | **Day B: Kubernetes Basics** | ![Hoàn thành](https://img.shields.io/badge/Hoàn_thành-brightgreen) | Tìm hiểu mô hình Container Orchestration, Pods, Services, Probes và thiết lập minikube cục bộ | [Xem chi tiết](cloud/w8/day-b/) |
| | **Day C: Terraform Advanced** | ![Hoàn thành](https://img.shields.io/badge/Hoàn_thành-brightgreen) | Quản lý State (S3/DynamoDB), Modules, tham gia Live Q&A và làm Bài kiểm tra số 1 | [Xem chi tiết](cloud/w8/day-c/) |
| | **Lab: Mini K8s Platform** | ![Hoàn thành](https://img.shields.io/badge/Hoàn_thành-brightgreen) | Thực hành triển khai cụm Kubernetes Kind trên EC2 với định tuyến ALB động 1-click | [Xem chi tiết](cloud/w8/lab/) |
| | **Reflection W8** | ![Hoàn thành](https://img.shields.io/badge/Hoàn_thành-brightgreen) | Ghi chép nhật ký phản hồi và bài học rút ra sau mỗi ngày | [Xem chi tiết](cloud/w8/reflection.md) |
| **W9** | **Day A: GitOps & CI/CD** | ![Hoàn thành](https://img.shields.io/badge/Hoàn_thành-brightgreen) | Tìm hiểu triết lý GitOps, Push vs Pull, ArgoCD vs Flux, App-of-apps, Sync Waves & Hooks, và CI/CD với GitHub Actions | [Xem chi tiết](cloud/w9/day-a/theory/01_gitops_principles.md) |
| | **Day B: Observability** | ![Hoàn thành](https://img.shields.io/badge/Hoàn_thành-brightgreen) | Tìm hiểu OTel, Prometheus, Grafana, Loki, thiết lập SLOs/SLIs và Multi-window burn rate alert | [Xem chi tiết](cloud/w9/day-b/theory/01_observability_concepts.md) |
| | **Day C: Canary Delivery** | ![Hoàn thành](https://img.shields.io/badge/Hoàn_thành-brightgreen) | Tìm hiểu Progressive Delivery, Argo Rollouts, AnalysisTemplate và tiêu chí tự động rollback | [Xem chi tiết](cloud/w9/day-c/theory/01_progressive_delivery_concepts.md) |
| | **Lab: GitOps & Observability** | ![Hoàn thành](https://img.shields.io/badge/Hoàn_thành-brightgreen) | Thực hành GitOps hóa nền tảng W8, tích hợp bộ công cụ đo lường SLOs và triển khai Canary | [Xem chi tiết](cloud/w9/lab/evidence_pack.md) |
| | **Reflection W9** | ![Hoàn thành](https://img.shields.io/badge/Hoàn_thành-brightgreen) | Nhật ký tự học và đánh giá phản hồi hàng ngày Tuần 9 | [Xem chi tiết](cloud/w9/reflection.md) |
| **W10**| **Day A: RBAC & Admission Policy** | ![Hoàn thành](https://img.shields.io/badge/Hoàn_thành-brightgreen) | Thiết lập phân quyền RBAC, ServiceAccount, cơ chế K8s Admission Controllers và chính sách kiểm duyệt Gatekeeper (Rego) | [Xem chi tiết](cloud/w10/day-a/theory/01_rbac_foundations.md) |
| | **Day B: Secrets & Supply Chain** | ![Lên kế hoạch](https://img.shields.io/badge/Lên_kế_hoạch-grey) | Tìm hiểu AWS Secrets Manager, External Secrets Operator (ESO), quét ảnh Trivy và ký ảnh Cosign | [Thư mục Day B](cloud/w10/day-b/) |
| | **Day C: Platform Integration** | ![Lên kế hoạch](https://img.shields.io/badge/Lên_kế_hoạch-grey) | Tích hợp toàn bộ hệ thống, LimitRange, ResourceQuota, Chaos Engineering và viết Runbooks | [Thư mục Day C](cloud/w10/day-c/) |
| | **Lab: Hardening & Enforcement** | ![Lên kế hoạch](https://img.shields.io/badge/Lên_kế_hoạch-grey) | Thực hành khắc phục 6 lỗ hổng bảo mật của cụm K8s và áp dụng chính sách Gatekeeper | [Thư mục Lab](cloud/w10/lab/) |
| | **Reflection W10** | ![Đang thực hiện](https://img.shields.io/badge/Đang_thực_hiện-yellow) | Nhật ký tự học và đánh giá phản hồi hàng ngày Tuần 10 | [Xem chi tiết](cloud/w10/reflection.md) |
| **W11**| **Capstone - Tuần 1** | ![Lên kế hoạch](https://img.shields.io/badge/Lên_kế_hoạch-grey) | Phối hợp liên đội sản xuất, phân tích yêu cầu và thiết kế kiến trúc hệ thống | [Capstone W11](capstone/w11/) |
| **W12**| **Capstone - Tuần 2 & Demo**| ![Lên kế hoạch](https://img.shields.io/badge/Lên_kế_hoạch-grey) | Tinh chỉnh hệ thống, báo cáo nghiệm thu và thuyết trình Capstone (03/07/2026) | [Capstone W12](capstone/w12/) |


---

## Cấu trúc thư mục dự án

Cấu trúc các thư mục được tổ chức theo đúng tiêu chuẩn yêu cầu của chương trình Phase 2:

```text
├── cloud/
│   ├── w8/                  # Tuần 8: Nền tảng IaC & Kubernetes
│   │   ├── day-a/           # Day A: Khởi đầu với Terraform (IaC, HCL, CLI)
│   │   ├── day-b/           # Day B: Kiến trúc Kubernetes & cài đặt minikube
│   │   ├── day-c/           # Day C: Quản lý nâng cao với State & Modules
│   │   ├── lab/             # Onsite Lab: Triển khai Mini Kubernetes Platform
│   │   └── reflection.md    # Nhật ký tự học và phản hồi hàng ngày
│   ├── w9/                  # Tuần 9: Triển khai GitOps, Observability & Canary
│   │   ├── day-a/           # Day A: GitOps & CI/CD (ArgoCD & GitHub Actions)
│   │   ├── day-b/           # Day B: Observability (OTel, Prometheus, Grafana)
│   │   ├── day-c/           # Day C: Canary Delivery (Argo Rollouts)
│   │   ├── lab/             # Lab thực hành tổng hợp Tuần 9
│   │   └── reflection.md    # Nhật ký tự học và phản hồi hàng ngày
│   └── w10/                 # Tuần 10: Secure & Operate (RBAC, Secrets, Policies)
│       ├── day-a/           # Day A: RBAC & Admission Policy (OPA Gatekeeper)
│       ├── day-b/           # Day B: Secrets Rotation (ESO) & Supply Chain Security
│       ├── day-c/           # Day C: Platform Integration & Runbooks
│       ├── lab/             # Lab thực hành dọn dẹp và thắt chặt bảo mật cụm
│       └── reflection.md    # Nhật ký tự học và phản hồi hàng ngày
├── capstone/
│   ├── w11/                 # Capstone giai đoạn 1 (Thiết kế & Khởi tạo)
│   └── w12/                 # Capstone giai đoạn 2 (Hoàn thiện & Thuyết trình)
└── README.md                # Trang chủ danh mục dự án cá nhân
```