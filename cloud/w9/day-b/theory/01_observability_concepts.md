# Chuyên đề 01: Nền tảng Observability và Kiến trúc OpenTelemetry

## 1. Phân biệt Monitoring và Observability

Trong vận hành hệ thống phần mềm hiện đại, đặc biệt là hệ thống phân tán (microservices), hai khái niệm Monitoring và Observability thường được sử dụng song hành nhưng có bản chất rất khác nhau:

### Monitoring (Giám sát)
*   **Mục tiêu**: Trả lời câu hỏi "Hệ thống có đang hoạt động bình thường hay không?" và "Cái gì đang bị hỏng?".
*   **Đặc điểm**: Tập trung vào các chỉ số định sẵn (pre-defined metrics) dựa trên các sự cố đã biết trước (known-unknowns). Ví dụ: Cảnh báo khi CPU utilization vượt quá 90%, hoặc tỉ lệ lỗi HTTP 500 của API Gateway vượt quá 5%.
*   **Cách tiếp cận**: Thụ động, dựa trên các quy tắc tĩnh (static rules) để phát hiện triệu chứng (symptoms).

### Observability (Khả năng quan sát)
*   **Mục tiêu**: Trả lời câu hỏi "Tại sao hệ thống lại bị hỏng?" và "Điều gì đang xảy ra bên trong hệ thống?".
*   **Đặc điểm**: Cho phép kỹ sư suy luận trạng thái bên trong của hệ thống dựa trên các đầu ra dữ liệu của nó (telemetry data) mà không cần phải thay đổi mã nguồn hay triển khai lại ứng dụng. Tập trung vào việc điều tra các sự cố chưa từng biết trước (unknown-unknowns).
*   **Cách tiếp cận**: Chủ động, cung cấp khả năng truy vấn chéo dữ liệu để tìm ra nguyên nhân gốc rễ (root cause).

---

## 2. Ba Cột trụ của Observability (Metrics, Traces, Logs)

Để đạt được Observability, hệ thống cần thu thập và liên kết ba loại dữ liệu telemetry cơ bản (thường được gọi là bộ ba MEL):

### Metrics (Chỉ số)
*   **Khái niệm**: Dữ liệu số học được tổng hợp và đo lường theo thời gian (time-series data).
*   **Đặc tính**: Dung lượng lưu trữ nhỏ, hiệu năng truy vấn cao. Phù hợp nhất cho việc thiết lập dashboard giám sát tổng quan và kích hoạt cảnh báo (alerting).
*   **Ví dụ**: Request rate, error rate, CPU/Memory usage, queue length.

### Traces (Vết yêu cầu)
*   **Khái niệm**: Biểu diễn toàn bộ hành trình (end-to-end path) của một request đi qua các thành phần khác nhau của hệ thống phân tán.
*   **Đặc tính**: Bao gồm một chuỗi các Span. Mỗi Span đại diện cho một đơn vị công việc (ví dụ: một truy vấn SQL, một cuộc gọi HTTP sang service khác). Giúp xác định chính xác điểm nghẽn độ trễ (latency bottleneck) và lỗi kết nối liên dịch vụ.
*   **Ví dụ**: Request A đi qua Gateway (5ms) -> Auth Service (10ms) -> Database Query (150ms).

### Logs (Nhật ký)
*   **Khái niệm**: Bản ghi dạng văn bản (text hoặc JSON) ghi nhận lại một sự kiện cụ thể xảy ra tại một mốc thời gian cụ thể.
*   **Đặc tính**: Có độ phân giải cao (high cardinality), chứa nhiều chi tiết kỹ thuật nhưng tiêu tốn rất nhiều dung lượng lưu trữ. Là công cụ cuối cùng để debug và tìm hiểu chi tiết lỗi chương trình.
*   **Ví dụ**: `[ERROR] 2026-06-09 23:15:00: Connection timeout to database cluster on 10.0.1.20`.

---

## 3. Kiến trúc OpenTelemetry (OTel)

OpenTelemetry (OTel) là một dự án mã nguồn mở thuộc CNCF, cung cấp một chuẩn chung (standard APIs, SDKs, tooling) để tạo sinh, thu thập, xử lý và xuất dữ liệu telemetry (metrics, traces, logs) sang các hệ thống lưu trữ backend khác nhau (vendor-agnostic).

Kiến trúc OTel gồm hai thành phần cốt lõi: OTel SDK và OTel Collector.

```text
[ Application (OTel SDK) ] ──► (OTLP) ──► [ OTel Collector ] ──► (Scrape / Push) ──► [ Backends ]
                                             ├── Receivers                            ├── Prometheus (Metrics)
                                             ├── Processors                           ├── Loki (Logs)
                                             └── Exporters                            └── Temp/Jaeger (Traces)
```

### OTel SDK
Là bộ thư viện được tích hợp trực tiếp vào mã nguồn ứng dụng (ví dụ: Go, Java, Python, Node.js). OTel SDK chịu trách nhiệm tự động (auto-instrumentation) hoặc thủ công (manual instrumentation) tạo ra các metrics, traces, logs từ bên trong code của ứng dụng và gửi chúng ra ngoài qua giao thức OTLP (OpenTelemetry Protocol).

### OTel Collector
Là một dịch vụ trung gian hoạt động độc lập (thường chạy dưới dạng Sidecar hoặc DaemonSet trong Kubernetes). OTel Collector nhận dữ liệu từ OTel SDK, xử lý dữ liệu và đẩy sang các backend lưu trữ. Quy trình xử lý của OTel Collector dựa trên luồng pipeline gồm ba thành phần:

*   **Receivers (Bộ nhận)**: Định nghĩa cách thức Collector nhận dữ liệu đầu vào. Hỗ trợ push-based (ví dụ: cổng OTLP gRPC/HTTP cho SDK gửi lên) và pull-based (ví dụ: đi scrape metrics từ Prometheus endpoint).
*   **Processors (Bộ xử lý)**: Thực hiện các thao tác biến đổi dữ liệu trước khi xuất đi. Nhiệm vụ chính gồm: batching (gộp dữ liệu gửi hàng loạt để giảm tải mạng), memory limiting (giới hạn RAM tiêu thụ), filter (lọc bớt dữ liệu thừa), và attribute manipulation (thêm/sửa tag định danh hệ thống).
*   **Exporters (Bộ xuất)**: Định nghĩa nơi gửi dữ liệu đầu ra. Chuyển đổi dữ liệu OTel sang định dạng tương ứng của backend đích và đẩy đi (ví dụ: export Prometheus metrics, export Loki logs, export Jaeger traces).
