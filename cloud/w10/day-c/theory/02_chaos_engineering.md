# Chuyên đề 02: Kiểm thử Hủy hoại (Chaos Engineering) trên Kubernetes

## 1. Khái niệm Chaos Engineering
*   **Chaos Engineering (Kỹ nghệ hỗn loạn)** là kỷ luật thực nghiệm bằng cách chủ động tiêm các lỗi hoặc sự cố giả lập vào hệ thống phần mềm nhằm đo lường khả năng chịu tải, tính ổn định và phát hiện sớm các điểm yếu thiết kế tiềm ẩn trước khi chúng gây ra sự cố thực tế trên môi trường Production.
*   **Triết lý**: Thay vì hy vọng hệ thống không lỗi, chúng ta chủ động giả định lỗi sẽ xảy ra ở bất kỳ đâu, bất kỳ lúc nào để thiết kế hệ thống có khả năng phục hồi tự động (Resilience).

---

## 2. Tại sao cần Chaos Test trên cụm Kubernetes?
Mặc dù Kubernetes cung cấp nhiều cơ chế tự động hóa mạnh mẽ như tự động khởi động lại container (Self-Healing), cân bằng tải, tự động co giãn (Autoscaling), hệ thống vẫn có thể gặp lỗi do các cấu hình sai lệch:
*   **Xác thực khả năng tự phục hồi (Self-Healing)**: Khi một Pod bị kill đột ngột, ReplicaSet có sinh lại Pod mới tức thì và không làm gián đoạn traffic (kết hợp với Graceful Shutdown và Probes)?
*   **Xác thực cơ chế Eviction**: Khi một Worker Node bị sập hoàn toàn (Node Loss), API Server có tự động dời các Pod bị ảnh hưởng sang các Node lành lặn khác một cách nhanh chóng không?
*   **Kiểm chứng khả năng chịu lỗi mạng (Network Resiliency)**: Khi mạng nội bộ bị trễ (Network Latency) hoặc mất gói tin (Packet Loss), ứng dụng có thực hiện cơ chế Retry, Timeout, Circuit Breaker hợp lý không?

---

## 3. Các công cụ Chaos Engineering phổ biến
*   **Chaos Mesh** (CNCF Sandbox Project):
    *   Cung cấp giao diện Web UI thân thiện giúp dễ dàng tạo và quản lý các thí nghiệm hỗn loạn.
    *   Hỗ trợ nhiều loại lỗi: Pod Chaos (kill, failure), Network Chaos (latency, loss), I/O Chaos, DNS Chaos, AWS Chaos (stop EC2 instance).
*   **LitmusChaos**:
    *   Thiết kế chuẩn Cloud-Native dựa trên Kubernetes Operator và Custom Resource Definitions (CRD).
    *   Phù hợp chạy các kịch bản thử nghiệm tự động định kỳ (Chaos Workflows) tích hợp sâu vào CI/CD pipelines để đánh giá chỉ số khả năng chịu lỗi (Resilience Score).

---

## 4. Quy trình 4 bước thực hiện Chaos Testing an toàn
Để tránh việc chaos test làm sập hệ thống thật một cách không kiểm soát, quy trình thực hiện phải tuân thủ nghiêm ngặt:

1.  **Xác định Trạng thái Bình thường (Steady State)**:
    *   Đo lường các chỉ số kỹ thuật và nghiệp vụ chủ chốt (SLI/SLO) khi hệ thống chạy bình thường. Ví dụ: HTTP Success Rate >= 99.9%, Latency p95 <= 200ms.
2.  **Đưa ra Giả thuyết (Hypothesis)**:
    *   "Giả sử nếu một node chứa cơ sở dữ liệu Replica bị tắt đột ngột, hệ thống vẫn duy trì được Steady State nhờ cơ chế tự động chuyển đổi của cụm DB."
3.  **Tiêm lỗi (Inject Chaos)**:
    *   Sử dụng công cụ (như Chaos Mesh) để tiêm lỗi cụ thể (ví dụ: giả lập mất kết nối mạng 80% tới node database).
4.  **Phân tích tác động & Khắc phục**:
    *   Đối chiếu các chỉ số thu được với Steady State ban đầu.
    *   Nếu giả thuyết bị bác bỏ (ví dụ: HTTP Success Rate giảm xuống 40%), ta đã tìm thấy điểm yếu thiết kế (Single Point of Failure). Nhóm phát triển tiến hành vá lỗi và lặp lại thử nghiệm.
*   **Nguyên tắc**: Bắt đầu tiêm lỗi với phạm vi nhỏ (Blast Radius tối thiểu), sau khi hệ thống chứng minh được độ chịu lỗi thì tăng dần quy mô. Luôn có phương án rollback khẩn cấp (Emergency Abort) để dừng thí nghiệm ngay lập tức nếu cụm gặp nguy cơ sập diện rộng.
