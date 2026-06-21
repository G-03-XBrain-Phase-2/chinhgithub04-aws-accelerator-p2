# Chuyên đề 03: Ký số ảnh Container (Cosign & Sigstore)

## 1. Mối đe dọa từ Tấn công Chuỗi Cung ứng (Supply Chain Attacks)
*   **Nguy cơ tráo đổi ảnh (Image Poisoning)**: Kẻ tấn công có thể chiếm quyền điều khiển Container Registry hoặc can thiệp vào mạng truyền tải để tráo đổi ảnh container gốc bằng một ảnh có chứa mã độc nhưng giữ nguyên tag phiên bản (ví dụ: `api:1.0.0`).
*   **Tính toàn vẹn của mã nguồn**: Không có gì đảm bảo rằng ảnh đang chạy trên cụm Kubernetes thực sự được biên dịch từ đúng commit sạch trên GitHub Actions, trừ khi ta có cơ chế xác minh nguồn gốc xuất xứ (Provenance) đáng tin cậy.

---

## 2. Giải pháp Ký số ảnh Container với Cosign
**Cosign** (thuộc dự án Sigstore của CNCF) là tiêu chuẩn công nghiệp giúp ký số và xác thực chữ ký của các tài nguyên phần mềm, đặc biệt là ảnh container OCI.
*   Chữ ký sau khi ký sẽ được đẩy lên Container Registry dưới dạng một tệp metadata đặc biệt liên kết chặt chẽ với SHA digest của ảnh container gốc.

---

## 3. Cơ chế Ký số dựa trên Khóa (Key-based Signing)
Đây là cơ chế truyền thống sử dụng cặp khóa mật mã không đối xứng (Asymmetric Key Pair):

1.  **Khởi tạo cặp khóa**:
    ```bash
    cosign generate-key-pair
    ```
    *   Lệnh sinh ra tệp khóa bí mật `cosign.key` (được bảo vệ bằng mật khẩu) và khóa công khai `cosign.pub`.
2.  **Ký ảnh trong CI Pipeline**:
    *   Khóa bí mật và mật khẩu được nạp vào GitHub Secrets của kho lưu trữ.
    *   Sau khi build ảnh thành công, CI chạy lệnh:
        ```bash
        cosign sign --key env://COSIGN_PRIVATE_KEY <registry>/<image>:<tag>
        ```
3.  **Xác thực**:
    *   Bất kỳ ai có khóa công khai `cosign.pub` đều có thể kiểm tra tính toàn vẹn của ảnh:
        ```bash
        cosign verify --key cosign.pub <registry>/<image>:<tag>
        ```

---

## 4. Cơ chế Ký số không cần Khóa (Keyless Signing / OIDC)
Cơ chế ký dựa trên khóa vẫn tồn tại rủi ro rò rỉ khóa bí mật hoặc hết hạn khóa. Sigstore cung cấp giải pháp **Keyless Signing** sử dụng danh tính ngắn hạn thông qua OIDC.

### Các thành phần chính trong mô hình Keyless:
*   **OpenID Connect (OIDC)**: GitHub Actions đóng vai trò là OIDC Identity Provider phát hành token xác minh danh tính của workflow.
*   **Fulcio (Certificate Authority)**: Nhận OIDC Token, xác thực và phát hành một chứng chỉ số ngắn hạn (chỉ có hiệu lực trong 10 phút) gắn liền với danh tính email hoặc GitHub workflow đó.
*   **Rekor (Transparency Log)**: Sổ cái lưu trữ thông tin giao dịch ký số. Một khi đã ghi vào Rekor, thông tin chữ ký không thể bị sửa đổi hay xóa bỏ (immutable audit log).
*   **Xác thực**: Khi deploy, Kubernetes Admission Controller kiểm tra chứng chỉ nằm trong registry, đối chiếu log trên Rekor và xác minh xem ảnh có đúng được ký bởi workflow của GitHub repository hợp lệ hay không.
