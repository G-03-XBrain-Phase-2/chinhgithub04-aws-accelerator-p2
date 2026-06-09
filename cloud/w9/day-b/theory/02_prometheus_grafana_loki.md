# Chuyên đề 02: Bộ Công cụ Giám sát Prometheus, Grafana và Loki (PLG Stack)

Trong quản trị hạ tầng Kubernetes, bộ công cụ Prometheus, Grafana và Loki (PLG Stack) là giải pháp mã nguồn mở tiêu chuẩn giúp quản lý tập trung toàn bộ metrics và logs của hệ thống.

```text
  [ Kubernetes Nodes / Pods ]
     │                   │
     ▼ (Scrape Metrics)  ▼ (Push Logs via Promtail/Fluentbit)
[ Prometheus ]      [ Grafana Loki ]
     │                   │
     └─────────┬─────────┘
               ▼ (Query / Visualize)
          [ Grafana ]
```

---

## 1. Prometheus: Giám sát Chỉ số (Metrics)

Prometheus là một hệ thống giám sát và cảnh báo mã nguồn mở, hoạt động theo cơ chế pull-based time-series.

### Cơ chế Pull-based Metrics Scraping
Khác biệt với phần lớn các hệ thống giám sát truyền thống bắt ứng dụng phải tự gửi dữ liệu lên (push-based), Prometheus chủ động gửi các truy vấn HTTP GET tới các endpoint `/metrics` của ứng dụng hoặc agent giám sát để kéo (scrape) dữ liệu về theo chu kỳ được cấu hình sẵn (scrape interval).

### Cơ sở dữ liệu TSDB (Time Series Database)
Prometheus lưu trữ metrics dưới dạng dữ liệu chuỗi thời gian (time-series). Mỗi bản ghi bao gồm một mốc thời gian (timestamp) và một giá trị số thực (float64). Dữ liệu được tối ưu hóa lưu trữ nén trên ổ đĩa cứng, phù hợp cho việc truy vấn dữ liệu lớn rất nhanh.

### Ngôn ngữ truy vấn PromQL
PromQL (Prometheus Query Language) là ngôn ngữ truy vấn mạnh mẽ cho phép lọc, tính toán và xử lý toán học trên dữ liệu time-series thời gian thực (ví dụ: tính toán tỉ lệ lỗi, phần trăm sử dụng CPU trung bình của cụm).

### Exporters
Với các dịch vụ bên ngoài không hỗ trợ sẵn endpoint `/metrics` (ví dụ: hệ điều hành Linux, MySQL, Nginx), Prometheus sử dụng các phần mềm cài thêm gọi là Exporters (như Node Exporter để thu thập metric OS, Kube-State-Metrics để thu thập trạng thái tài nguyên Kubernetes) đóng vai trò làm cầu nối chuyển đổi dữ liệu và expose endpoint `/metrics`.

---

## 2. Loki: Giám sát Nhật ký (Logs)

Loki là một hệ thống quản lý log được thiết kế để tối ưu hóa hiệu năng và chi phí lưu trữ, lấy cảm hứng từ Prometheus.

### Metadata-based Indexing (Đánh chỉ mục nhãn)
Điểm khác biệt cốt lõi giữa Loki và Elasticsearch là Loki **không đánh chỉ mục (index) nội dung văn bản của log**. Thay vào đó, Loki chỉ đánh chỉ mục cho các nhãn (metadata labels) giống hệt cấu trúc nhãn của Prometheus (ví dụ: `namespace="production"`, `app="web-app"`).
*   **Ưu điểm**: Dung lượng lưu trữ giảm đi hàng chục lần so với Elasticsearch, chi phí vận hành rẻ hơn rất nhiều, tốc độ nạp log cực nhanh.
*   **Nhược điểm**: Truy vấn nội dung log thô sẽ chậm hơn Elasticsearch đối với các tập dữ liệu khổng lồ do phải quét trực tiếp.

### LogQL
Loki sử dụng ngôn ngữ truy vấn LogQL, có cú pháp rất giống với PromQL. LogQL cho phép lập trình viên lọc log theo nhãn, tìm kiếm chuỗi văn bản bằng Regex, và đặc biệt là chuyển đổi log thô thành metrics thời gian thực (ví dụ: đếm số lượng log chứa từ khóa `ERROR` để vẽ biểu đồ).

---

## 3. Grafana: Trực quan hóa Dữ liệu (Visualization)

Grafana đóng vai trò là giao diện hiển thị trung tâm, kết nối tất cả các nguồn dữ liệu giám sát (Data Sources).

*   **Unified Dashboard**: Grafana cho phép hiển thị đồng thời cả Metrics từ Prometheus và Logs từ Loki trên cùng một màn hình (Dashboard). Khi người dùng kéo chuột zoom vào một mốc thời gian bị lỗi trên biểu đồ metrics, Grafana tự động đồng bộ hóa mốc thời gian đó để hiển thị chính xác các dòng logs lỗi tương ứng từ Loki.
*   **Variables**: Hỗ trợ thiết lập các biến động trên Dashboard (ví dụ: dropdown chọn Namespace, Pod, Node), giúp Dashboard có khả năng tái sử dụng cao cho nhiều ứng dụng và môi trường khác nhau.
*   **Alerting**: Grafana Alerting cho phép thiết lập các quy tắc cảnh báo trực tiếp từ kết quả truy vấn dữ liệu và tích hợp gửi thông báo tới Slack, Discord, PagerDuty, Webhooks.
