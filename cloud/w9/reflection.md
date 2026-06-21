# W9 Learning Journal & Reflection — Deliver Smartly: GitOps + Observability + Canary

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

---

### Thứ Ba, 09/06/2026 — Day B: Observability Foundations

> **Nhiệm vụ:** Tự học lý thuyết Observability, ba cột trụ Metrics/Traces/Logs, kiến trúc OpenTelemetry (OTel SDK & Collector), hệ sinh thái Prometheus/Loki/Grafana (PLG Stack), phương pháp thiết lập SLO/SLI (Availability & Latency) và cơ chế cảnh báo nâng cao Multi-window Multi-burn-rate Alerting.

#### 1. Lý thuyết thu hoạch được

*   **Observability vs Monitoring**: Phân biệt rõ Monitoring tập trung vào việc cảnh báo triệu chứng (symptoms) của các sự cố đã biết trước (known-unknowns). Observability cung cấp khả năng suy luận trạng thái nội tại hệ thống để tìm hiểu nguyên nhân gốc rễ (root cause) của các sự cố chưa từng biết trước (unknown-unknowns).
*   **Ba cột trụ của Observability**: Nắm vững các thuộc tính của bộ ba Metrics (độ nén cao, phù hợp alerting), Traces (cho thấy hành trình yêu cầu qua các microservices, định vị latency bottlenecks), và Logs (bản ghi chi tiết độ phân giải cao phục vụ debug lỗi).
*   **Kiến trúc OpenTelemetry**: Tìm hiểu mô hình OTel SDK tích hợp trong ứng dụng để tạo sinh dữ liệu telemetry chuyển đi qua giao thức OTLP, và OTel Collector hoạt động độc lập thực hiện xử lý dữ liệu qua pipeline ba bước: Receivers (nhận) -> Processors (xử lý, batching, filter) -> Exporters (đẩy dữ liệu ra backends).
*   **Hệ sinh thái PLG Stack**: 
    *   *Prometheus*: Thu thập metrics qua cơ chế pull-based scraping, lưu trữ tối ưu trong TSDB, truy vấn qua ngôn ngữ PromQL.
    *   *Loki*: Quản lý log tối ưu chi phí thông qua cơ chế metadata-based indexing (chỉ đánh chỉ mục nhãn, không index nội dung log), truy vấn qua ngôn ngữ LogQL.
    *   *Grafana*: Bảng trực quan hóa hợp nhất (unified dashboard) kết nối đa nguồn dữ liệu.
*   **Phương pháp luận SLO/SLI**: Phân biệt rõ SLI (chỉ số đo lường thực tế), SLO (mục tiêu cam kết tin cậy nội bộ), SLA (hợp đồng pháp lý thương mại). Thiết lập công thức đo lường Availability và Latency dựa trên tỉ lệ request tốt trên tổng request.
*   **Error Budget & Burn Rate Alerting**: Hiểu rõ ý nghĩa điều hòa của Error Budget giữa Dev và SRE. Nghiên cứu cơ chế Multi-window Multi-burn-rate Alerting của Google giúp cân bằng độ chính xác và tốc độ báo lỗi bằng việc kết hợp đồng thời Long Window và Short Window cho cả Fast Burn Rate (cảnh báo sập nguồn nhanh) và Slow Burn Rate (cảnh báo rò rỉ âm thầm).

#### 2. Kết quả thực hành

Em đã hoàn thành việc thiết lập cấu trúc thư mục học tập cho Day B tại thư mục `cloud/w9/day-b/` và soạn thảo hệ thống tài liệu chuyên đề lý thuyết chuyên sâu:
*   [x] Khởi tạo thư mục và hoàn thiện tệp chuyên đề `theory/01_observability_concepts.md` về nền tảng Observability và kiến trúc OpenTelemetry.
*   [x] Hoàn thiện tệp chuyên đề `theory/02_prometheus_grafana_loki.md` về bộ công cụ PLG Stack (Prometheus, Grafana, Loki).
*   [x] Hoàn thiện tệp chuyên đề `theory/03_slo_sli_methodology.md` về phương pháp luận thiết lập SLI, SLO và Error Budget.
*   [x] Hoàn thiện tệp chuyên đề `theory/04_burn_rate_alerting.md` về cơ chế cảnh báo đa khung thời gian Multi-window Multi-burn-rate Alerting.

---

### Thứ Tư, 10/06/2026 — Day C: Progressive Delivery (Canary)

> **Nhiệm vụ:** Tự học lý thuyết Progressive Delivery, so sánh các chiến lược deployment (Rolling Update, Blue/Green, Canary), nghiên cứu kiến trúc Argo Rollouts, cấu trúc tài nguyên Rollout CRD, cơ chế định tuyến lưu lượng truy cập và tự động hóa phân tích qua AnalysisTemplate truy vấn Prometheus cùng cơ chế auto-rollback.

#### 1. Lý thuyết thu hoạch được

*   **Bản chất của Progressive Delivery**: Nhận thức được đây là mô hình cải tiến của Continuous Delivery giúp phát hành phần mềm an toàn bằng cách kiểm soát blast radius, tăng dần traffic và tự động rollback dựa trên hệ thống đo lường chất lượng thực tế.
*   **So sánh các chiến lược deployment**:
    *   *Kubernetes Rolling Update*: Đơn giản nhưng thiếu tính năng phân tách traffic theo phần trăm và không tự động rollback dựa trên metrics sức khỏe.
    *   *Blue/Green*: Chuyển đổi traffic nhanh và an toàn nhưng tiêu tốn gấp đôi tài nguyên hệ thống (100% buffer).
    *   *Canary*: Cân bằng tối ưu giữa bảo vệ người dùng, tiết kiệm tài nguyên hạ tầng và hỗ trợ kiểm thử tự động với lượng người dùng nhỏ.
*   **Kiến trúc Argo Rollouts**:
    *   Sử dụng CRD `Rollout` thay thế cho `Deployment` Kubernetes.
    *   Định nghĩa các bước chia traffic (`steps`, `setWeight`, `pause`) giúp tùy biến tối đa quy trình phát hành.
    *   Định tuyến lưu lượng truy cập thông qua sự kết hợp của Stable Service và Canary Service, tích hợp với Ingress Controllers (như Nginx, AWS ALB) để điều tiết HTTP traffic.
*   **Tự động hóa đánh giá và Auto-rollback**:
    *   Phân biệt rõ `AnalysisTemplate` (bản vẽ kỹ thuật đo lường), `ClusterAnalysisTemplate` (phạm vi toàn cụm) và `AnalysisRun` (thực thể chạy truy vấn thực tế).
    *   Thiết lập truy vấn PromQL tự động quét Prometheus định kỳ (`interval`) để đo lường success rate và latency.
    *   Định nghĩa tiêu chí hủy bỏ (`failureLimit`, `consecutiveErrorLimit`) để kích hoạt auto-rollback tức thì khi phát hiện chỉ số suy yếu hoặc cạn kiệt Error Budget (Burn Rate Alerting), đưa traffic 100% về Stable Service và dọn dẹp các Canary Pods.

#### 2. Kết quả thực hành

Em đã hoàn thành việc thiết lập cấu trúc thư mục học tập cho Day C tại thư mục `cloud/w9/day-c/` và soạn thảo hệ thống tài liệu chuyên đề lý thuyết chuyên sâu:
*   [x] Khởi tạo thư mục và hoàn thiện tệp chuyên đề `theory/01_progressive_delivery_concepts.md` về khái niệm Progressive Delivery và so sánh Argo Rollouts vs Flagger.
*   [x] Hoàn thiện tệp chuyên đề `theory/02_argo_rollouts_crds.md` về cấu trúc tài nguyên Rollout CRD và cơ chế định tuyến.
*   [x] Hoàn thiện tệp chuyên đề `theory/03_analysis_and_auto_rollback.md` về tự động hóa phân tích Canary qua Prometheus và cơ chế auto-rollback.

---

### Thứ Năm + Thứ Sáu, 11-12/06/2026 — Onsite Lab: GitOps & Observability Automation

> **Nhiệm vụ:** Thực hành GitOps hóa nền tảng W8, tích hợp bộ công cụ đo lường SLOs và triển khai Canary.

#### 1. Lý thuyết thu hoạch được (Core Theoretical Takeaways)
*   **Quy trình GitOps-ify**: Hiểu rõ cách cấu trúc một GitOps repository chuẩn (chia tách thư mục `apps` chứa định nghĩa Application và `k8s` chứa manifests tài nguyên của từng microservice) giúp ArgoCD dễ dàng quản lý theo mô hình App-of-Apps.
*   **ServiceMonitor & Prometheus Custom Metrics**: Nắm vững phương pháp cấu hình `ServiceMonitor` để Prometheus tự động phát hiện (auto-discover) các endpoints và thu thập metrics tùy biến do ứng dụng Python Flask (`w9-api`) sinh ra.
*   **Tự động hóa Canary bằng AnalysisTemplate**: Hiểu rõ cách liên kết `Rollout` với `AnalysisTemplate` để tự động thực thi các truy vấn PromQL đo lường success-rate của Canary Pods, từ đó quyết định cho phép nâng cấp hay tự động Abort/Rollback mà không cần can thiệp thủ công.
*   **Cơ chế cảnh báo an toàn**: Nắm được phương thức bảo mật mật khẩu Gmail của Alertmanager thông qua Kubernetes Secret (thay vì viết trực tiếp lên Git) và cách cấu hình routing để gửi email cảnh báo tự động khi vi phạm ngưỡng SLO.

#### 2. Kết quả thực hành (Practical Checkpoint Evidence)
*   [x] Triển khai thành công cấu trúc App-of-Apps trên ArgoCD bằng Root Application trỏ tới các tài nguyên con.
*   [x] Kiểm chứng thành công tính năng **Self-Heal**: Khi scale thủ công số lượng Pod bằng lệnh `kubectl scale`, ArgoCD lập tức đồng bộ hóa và tự phục hồi (healing) về đúng cấu hình Git.
*   [x] Triển khai thành công bộ công cụ giám sát Prometheus, Grafana và Loki. Cấu hình thành công ServiceMonitor để thu thập metrics của dịch vụ Flask.
*   [x] **Thử nghiệm Canary thành công**: Triển khai Argo Rollouts cho dịch vụ API với cơ chế tự động phân tích Canary thông qua Prometheus.
*   [x] **Kiểm chứng Auto-Rollback**: Cố tình deploy phiên bản lỗi `v2` (tỉ lệ lỗi 50%). Hệ thống phát hiện vi phạm SLO (tỉ lệ lỗi > 5%), lập tức Abort quá trình nâng cấp, tự động Rollback 100% traffic về bản `v1` ổn định, đồng thời gửi email cảnh báo về hộp thư Gmail của quản trị viên.
*   [x] Lưu trữ toàn bộ hình ảnh chứng minh tại thư mục `cloud/w9/lab/media/` và viết báo cáo đầy đủ tại tệp tin [cloud/w9/lab/evidence_pack.md](file:///g:/XBrain/BaiTap/W8/chinhgithub04-aws-accelerator-p2/cloud/w9/lab/evidence_pack.md).
