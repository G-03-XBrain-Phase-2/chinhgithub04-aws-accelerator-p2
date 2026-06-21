# Chuyên đề 03: Quy trình xử lý sự cố (Incident Response & Runbooks)

## 1. Runbook / Playbook là gì?
*   **Runbook** (hoặc Playbook) là tài liệu hướng dẫn quy trình vận hành từng bước được chuẩn hóa nhằm giúp kỹ sư trực ban (On-call Engineer) hoặc đội ngũ SRE phát hiện, chẩn đoán và khắc phục nhanh chóng các sự cố cụ thể của hệ thống.
*   **Tầm quan trọng**: Giảm thiểu tối đa thời gian trung bình để phục hồi hệ thống (Mean Time to Resolution - MTTR), giảm thiểu sai sót do áp lực tâm lý khi xảy ra sự cố, và phân cấp quy trình xử lý rõ ràng.

---

## 2. Quy trình 6 bước ứng phó sự cố (AWS Incident Response Framework)

```text
  [ 1. Detect ] ──► [ 2. Triage ] ──► [ 3. Contain ]
                                             │
  [ 6. Post-mortem ] ◄── [ 5. Recover ] ◄── [ 4. Eradicate ]
```

1.  **Detect (Phát hiện)**: Sự cố được ghi nhận qua cảnh báo tự động (Alertmanager, Grafana Alarms, AWS CloudWatch) hoặc từ báo cáo người dùng.
2.  **Triage (Đánh giá & Phân loại)**: Xác định mức độ nghiêm trọng (P0/Critical - sập hệ thống, P1 - ảnh hưởng tính năng chính, P2 - lỗi nhỏ) và khoanh vùng phạm vi ảnh hưởng (Blast Radius).
3.  **Contain (Cách ly/Khoanh vùng)**: Thực hiện các hành động khẩn cấp để ngăn chặn sự cố lan rộng. Ví dụ: Ngắt kết nối mạng của Pod bị lỗi, cô lập EC2 bị hack bằng cách swap Security Group hạn chế kết nối.
4.  **Eradicate (Khắc phục nguyên nhân)**: Loại bỏ nguyên nhân gốc rễ. Ví dụ: Rollback phiên bản code lỗi qua `git revert`, dọn dẹp các tệp tin log rác làm đầy ổ cứng.
5.  **Recover (Phục hồi)**: Đưa dịch vụ trở lại trạng thái hoạt động bình thường, xác minh các chỉ số SLO và hệ thống giám sát đã chuyển sang màu xanh.
6.  **Post-mortem (Mổ xẻ sự cố)**: Họp rút kinh nghiệm không đổ lỗi (Blameless Post-mortem). Viết tài liệu Root Cause Analysis (RCA) để cải tiến hệ thống và cập nhật lại chính Runbook này nếu có bước chẩn đoán chưa tối ưu.

---

## 3. Bản mẫu Runbook chuẩn: Khắc phục lỗi cạn kiệt tài nguyên Pod (OOMKilled)

### 📌 Dấu hiệu nhận biết (Symptoms)
*   Cảnh báo Alertmanager báo động: `KubePodCrashLooping` hoặc `KubeMemoryOvercommit`.
*   Pod chuyển trạng thái liên tục: `CrashLoopBackOff` hoặc `OOMKilled`.

### 🔍 Chẩn đoán nhanh (Diagnostic Steps)
1.  Kiểm tra danh sách các Pod lỗi trong namespace `demo`:
    ```bash
    kubectl get pods -n demo --field-selector status.phase!=Running
    ```
2.  Kiểm tra lý do Pod bị Terminated:
    ```bash
    kubectl describe pod <pod-name> -n demo
    ```
    *   *Kết quả mong đợi*: Tìm kiếm dòng `Last State: Terminated` -> `Reason: OOMKilled` (Out of Memory - Container tiêu thụ RAM vượt mức limits quy định).
3.  Xem lịch sử tiêu thụ CPU/RAM thực tế của Pod:
    ```bash
    kubectl top pod <pod-name> -n demo --containers
    ```

### 🛠️ Các bước xử lý khẩn cấp (Mitigation Actions)

#### Phương án A: Tăng tài nguyên limits (Khắc phục nhanh)
Nếu ứng dụng tăng lượng tải thực tế và cấu hình limits cũ quá nhỏ:
1.  Chỉnh sửa file cấu hình Deployment trên Git (tuân thủ GitOps) để tăng `resources.limits.memory` và `resources.requests.memory`.
2.  Apply cấu hình mới và kiểm tra trạng thái Pod đã hoạt động ổn định chưa.

#### Phương án B: Kiểm tra cấu hình LimitRange của Namespace
Nếu Pod không tự khai báo tài nguyên và bị áp giá trị mặc định của LimitRange quá nhỏ:
1.  Kiểm tra cấu hình LimitRange trong namespace:
    ```bash
    kubectl get limitrange -n demo -o yaml
    ```
2.  Điều chỉnh giá trị `default` và `defaultRequest` của LimitRange cho phù hợp với yêu cầu tối thiểu của dịch vụ.

#### Phương án C: Điều tra rò rỉ bộ nhớ (Memory Leak)
Nếu biểu đồ RAM tăng dần đều theo đường thẳng tuyến tính mà không giảm:
1.  Báo cáo với nhóm phát triển ứng dụng (Developer) để rà soát mã nguồn (profiling), tìm kiếm các luồng kết nối không giải phóng hoặc cache quá mức.
