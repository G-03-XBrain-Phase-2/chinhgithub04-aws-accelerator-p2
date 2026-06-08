# Nhật ký Học tập và Phản hồi Tuần 09 - Deliver Smartly: GitOps + Observability + Canary

*   **Họ và tên:** Nguyễn Đức Chinh
*   **ID:** XB-DN26-080
*   **Group:** 3
*   **Tuần học:** Tuần 09 (08/06/2026 – 12/06/2026)
*   **Chuyên ngành:** Cloud / DevOps

---

## Nhật ký Học tập Hàng ngày (Daily Journal)

### Thứ Hai, 08/06/2026 — Day A: GitOps & CI/CD Foundations

> **Nhiệm vụ:** Tự học lý thuyết GitOps, so sánh các mô hình Push-based/Pull-based, so sánh các công cụ điều phối ArgoCD vs Flux, nghiên cứu mô hình thiết kế App-of-Apps, Sync Waves, Sync Hooks, cơ chế CI/CD hạ tầng bằng GitHub Actions (Plan-on-PR và Apply-on-Merge) và các chiến lược Rollback.

#### 1. Lý thuyết thu hoạch được

*   **Bản chất của GitOps**: Thấu hiểu 4 nguyên lý cốt lõi của OpenGitOps bao gồm: hệ thống được mô tả ở dạng khai báo (declarative), trạng thái được lưu trữ bất biến trên Git (versioned and immutable), tác nhân trong cụm tự động kéo cấu hình (auto-pull) và cơ chế tự động điều hòa liên tục (continuous reconciliation) giúp tự động sửa lỗi lệch cấu hình (drift detection & self-healing).
*   **Mô hình Push vs Pull**: 
    *   Mô hình Push-based truyền thống yêu cầu cấp quyền truy cập trực tiếp từ hệ thống CI bên ngoài vào cụm, dễ xảy ra lỗ hổng bảo mật và không có khả năng phát hiện lệch cấu hình tức thì.
    *   Mô hình Pull-based sử dụng Agent chạy ngay trong cụm, tăng tính bảo mật do không phải mở API Server ra ngoài và thực hiện vòng lặp điều hòa liên tục để đưa cụm về đúng cấu hình trên Git.
*   **Cơ chế nâng cao của ArgoCD**:
    *   **App-of-Apps**: Mẫu thiết kế quản lý tập trung nhiều ứng dụng con qua một ứng dụng gốc (Root App), giúp tự động hóa toàn bộ luồng khai báo cấu hình mà không cần tạo tay từng ứng dụng.
    *   **Sync Waves**: Cho phép định nghĩa thứ tự đồng bộ tài nguyên theo mức độ ưu tiên (chỉ số wave tăng dần) thay vì apply đồng thời, đảm bảo các phụ thuộc nền tảng (như namespace, secrets) được khởi tạo trước.
    *   **Sync Hooks**: Cơ chế kích hoạt các Job phụ trợ tại các thời điểm cụ thể trong vòng đời đồng bộ (như chạy database migration tại PreSync, thông báo Slack tại PostSync).
*   **CI/CD hạ tầng với GitHub Actions**: Nắm vững luồng kiểm thử hạ tầng Terraform:
    *   *Plan-on-PR*: Tự động chạy validate và plan khi mở PR, ghi nhận kết quả plan dưới dạng comment trên PR giúp người xem đánh giá rủi ro dễ dàng.
    *   *Apply-on-merge*: Tự động thực thi apply khi PR được merge vào nhánh chính.
*   **Chiến lược Rollback**: So sánh và nhận diện nhược điểm của `kubectl rollout undo` (gây mất đồng bộ với Git và bị ArgoCD ghi đè lại phiên bản lỗi ở chu kỳ tiếp theo). Khẳng định `git revert` là phương thức rollback chuẩn mực duy nhất trong GitOps giúp đồng bộ trạng thái, lưu vết lịch sử vĩnh viễn và đảm bảo an toàn vận hành.

#### 2. Kết quả thực hành

Em đã hoàn thành việc thiết lập cấu trúc thư mục học tập cho Day A tại thư mục `cloud/w9/day-a/` và soạn thảo hệ thống tài liệu chuyên đề lý thuyết chuyên sâu:
*   [x] Khởi tạo thư mục và hoàn thiện tệp chuyên đề `theory/01_gitops_principles.md` về triết lý GitOps và so sánh ArgoCD vs Flux CD.
*   [x] Hoàn thiện tệp chuyên đề `theory/02_argocd_patterns.md` về mô hình App-of-Apps, Sync Waves và Sync Hooks.
*   [x] Hoàn thiện tệp chuyên đề `theory/03_cicd_github_actions.md` về luồng tự động hóa CI/CD cho hạ tầng thông qua GitHub Actions (kèm mẫu YAML).
*   [x] Hoàn thiện tệp chuyên đề `theory/04_rollback_strategies.md` phân tích chuyên sâu chiến lược rollback qua Git.
