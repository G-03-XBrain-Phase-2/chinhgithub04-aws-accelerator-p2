# Chuyên đề 03: Tự động hóa Đánh giá Canary và Hủy bỏ Phát hành (Auto-rollback)

Một trong những thế mạnh lớn nhất của Argo Rollouts là khả năng tự động phân tích sức khỏe của phiên bản mới thông qua metrics thời gian thực để đưa ra quyết định tự động chuyển bước (Promote) hoặc hủy bỏ và hoàn nguyên (Abort/Rollback) mà không cần con người giám sát trực tiếp.

---

## 1. Phân biệt AnalysisTemplate, ClusterAnalysisTemplate và AnalysisRun

Argo Rollouts định nghĩa ba loại tài nguyên CRD phục vụ công tác phân tích:

*   **AnalysisTemplate**: Là một bản thiết kế (blueprint) định nghĩa cách thức đo lường hiệu năng của dịch vụ (ví dụ: truy vấn Prometheus nào cần chạy, tần suất quét bao lâu một lần, bao nhiêu lần lỗi thì dừng). Nó mang tính chất tái sử dụng cao cho nhiều Rollouts trong cùng một Namespace.
*   **ClusterAnalysisTemplate**: Tương tự như `AnalysisTemplate` nhưng có phạm vi hoạt động trên toàn cụm (Cluster-wide), cho phép chia sẻ cấu hình đo lường dùng chung giữa nhiều Namespace khác nhau.
*   **AnalysisRun**: Là một thực thể thực thi (instantiation) cụ thể của một `AnalysisTemplate`. Khi tài nguyên `Rollout` bắt đầu triển khai các bước Canary, Argo Rollouts Controller sẽ tự động tạo ra một `AnalysisRun` để chạy các câu lệnh truy vấn thực tế trên backend giám sát.

---

## 2. Cấu hình AnalysisTemplate Truy vấn Prometheus

Dưới đây là một tệp cấu hình `AnalysisTemplate` mẫu thực hiện kiểm tra tỉ lệ thành công của HTTP request (Success Rate) từ máy chủ Prometheus:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate-analysis
spec:
  metrics:
  - name: success-rate
    interval: 1m                   # Cứ mỗi 1 phút thực hiện truy vấn 1 lần
    successCondition: result[0] >= 0.99  # Điều kiện thành công: tỉ lệ HTTP request non-5xx phải >= 99%
    failureLimit: 3                # Cho phép truy vấn lỗi tối đa 3 lần trước khi đánh giá thất bại toàn cuộc
    provider:
      prometheus:
        address: http://prometheus-k8s.monitoring.svc:9090
        query: |
          sum(rate(http_requests_total{status!~"5.*",app="web-app"}[2m]))
          /
          sum(rate(http_requests_total{app="web-app"}[2m]))
```

---

## 3. Tiêu chí Hủy bỏ (Abort Criteria) và Cơ chế Auto-rollback

Trong cấu hình `AnalysisTemplate`, chúng ta thiết lập các tham số điều khiển để bảo vệ hệ thống:
*   **interval**: Chu kỳ lặp lại việc kiểm tra.
*   **failureLimit**: Số lần thất bại cho phép. Nếu câu lệnh truy vấn trả về kết quả vi phạm điều kiện `successCondition` vượt quá số lần cấu hình này, `AnalysisRun` sẽ chuyển sang trạng thái `Failed`.
*   **consecutiveErrorLimit**: Giới hạn số lần lỗi kết nối liên tiếp tới Prometheus Server (ví dụ: do nghẽn mạng). Nếu vượt ngưỡng, phân tích cũng tự hủy để đảm bảo an toàn.

### Vòng lặp Auto-rollback hoạt động như thế nào?

```text
       [ Rollout: Step - Canary 10% ]
                     │
                     ▼ (Tự động sinh ra)
             [ AnalysisRun ]
                     │
                     ▼ (Truy vấn liên tục)
             [ Prometheus Server ]
                     │
    ┌────────────────┴────────────────┐
    │ (Kết quả Success Rate tốt?)      │
    ▼ (Có - Synced)                   ▼ (Không - Failed)
[ Tiếp tục tăng Traffic ]        [ Kích hoạt Auto-rollback ]
                                 - Chuyển Ingress 100% về Stable
                                 - Hủy bỏ Canary Pods
                                 - Trả trạng thái Degraded
```

Khi `AnalysisRun` bị đánh giá là thất bại (`Failed`), Argo Rollouts Controller sẽ lập tức dừng toàn bộ quy trình deployment hiện tại và tự động thực hiện rollback:
1.  Ngay lập tức thay đổi cấu hình Ingress/Service Mesh để chuyển toàn bộ $100\%$ lưu lượng truy cập của người dùng về lại Stable Service ổn định cũ.
2.  Thu nhỏ (scale down) số lượng Canary Pods của phiên bản lỗi về 0.
3.  Đánh dấu trạng thái Rollout là `Degraded` (suy giảm) và gửi thông báo cảnh báo để đội ngũ kỹ sư điều tra nguyên nhân.

---

## 4. Tích hợp với SRE SLO & Burn Rate Alerting

Thay vì chỉ kiểm tra các chỉ số thô sơ như tỉ lệ HTTP error rate tức thời, một mô hình thiết kế cấp tiến hơn là tích hợp trực tiếp chỉ số **Burn Rate** (tốc độ tiêu hao ngân sách lỗi) vào `AnalysisTemplate`.

### Ý tưởng thực hiện
*   Nếu một đợt deploy phiên bản mới làm ứng dụng có tỉ lệ lỗi tăng nhẹ, nhưng kéo dài và làm tốc độ tiêu hao ngân sách lỗi vượt ngưỡng cho phép (ví dụ: Burn Rate $> 14.4$ trong 10 phút đầu tiên của đợt rollout), `AnalysisTemplate` sẽ phát hiện ngay thông qua truy vấn PromQL tương ứng.
*   Việc phát hiện Burn Rate tăng cao sẽ lập tức làm hỏng điều kiện của `AnalysisRun`, kích hoạt rollback tự động trước khi phiên bản lỗi này kịp tiêu thụ hết Error Budget của chu kỳ, bảo vệ an toàn tối đa cho cam kết SLO của hệ thống đối với khách hàng.
