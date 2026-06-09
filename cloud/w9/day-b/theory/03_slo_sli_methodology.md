# Chuyên đề 03: Phương pháp luận Thiết lập SLI, SLO và Quản lý Error Budget

Thiết lập hệ thống chỉ số đo lường độ tin cậy dịch vụ là nền tảng cốt lõi của kỹ nghệ SRE (Site Reliability Engineering). Nó giúp chuyển dịch các đánh giá định tính mơ hồ về sức khỏe hệ thống thành các chỉ số định lượng cụ thể.

---

## 1. Phân biệt SLI, SLO và SLA

### SLI (Service Level Indicator - Chỉ số mức dịch vụ)
*   **Bản chất**: Đo lường định lượng thực tế về hiệu năng hoạt động của một dịch vụ.
*   **Công thức chung**: 
    $$\text{SLI} = \frac{\text{Số lượng sự kiện hợp lệ (Good Events)}}{\text{Tổng số lượng sự kiện nhận được (Total Events)}} \times 100\%$$
*   **Ví dụ**: Tỉ lệ phần trăm các cuộc gọi API HTTP trả về mã code thành công (non-5xx) trong vòng 5 phút qua.

### SLO (Service Level Objective - Mục tiêu mức dịch vụ)
*   **Bản chất**: Giá trị mục tiêu hoặc phạm vi giá trị mong muốn cho một SLI, được thống nhất giữa các nhóm kỹ sư (Dev, Ops, Product).
*   **Công thức**: $\text{SLI} \ge \text{SLO}$
*   **Ví dụ**: Tỉ lệ HTTP request thành công phải đạt tối thiểu $99.9\%$ trong chu kỳ 30 ngày liên tiếp.

### SLA (Service Level Agreement - Thỏa thuận mức dịch vụ)
*   **Bản chất**: Cam kết hợp đồng pháp lý hoặc thương mại giữa nhà cung cấp dịch vụ và khách hàng sử dụng dịch vụ. SLA bao gồm các hình phạt tài chính (hoàn tiền, bồi thường) hoặc pháp lý nếu nhà cung cấp không đạt được mức độ tin cậy thỏa thuận.
*   **Mối liên hệ**: Thông thường, SLO luôn được thiết lập chặt chẽ hơn SLA để tạo ra một khoảng đệm an toàn phòng ngừa sự cố (ví dụ: SLO nội bộ là $99.9\%$, nhưng SLA cam kết với khách hàng chỉ là $99.0\%$).

---

## 2. Đo lường SLO cho Availability và Latency

Hai thuộc tính cơ bản nhất cần được thiết lập SLO cho bất kỳ dịch vụ web nào là Availability (Độ khả dụng) và Latency (Độ trễ):

### Availability SLI / SLO
Đo lường tỉ lệ thành công của các yêu cầu gửi tới dịch vụ.
*   **Good Events**: Số lượng request trả về HTTP status code nhỏ hơn 500 (loại trừ các lỗi do client tự gây ra như HTTP 4xx).
*   **Total Events**: Tổng số lượng request hợp lệ được gửi tới ứng dụng.
*   **Công thức**:
    $$\text{SLI}_{\text{Availability}} = \frac{\text{Count}(\text{http\_requests\_total}\{\text{status} \not\approx 5\text{xx}\})}{\text{Count}(\text{http\_requests\_total})} \times 100\%$$

### Latency SLI / SLO
Đo lường tốc độ phản hồi của hệ thống. Thông thường không sử dụng giá trị trung bình (average latency) vì nó che giấu các điểm trễ cực hạn (outliers). Thay vào đó, SRE sử dụng phân vị (percentiles) hoặc đặt ngưỡng giới hạn độ trễ chấp nhận được.
*   **Good Events**: Số lượng request có thời gian phản hồi nhỏ hơn hoặc bằng một ngưỡng cụ thể $T$ (ví dụ: $200\text{ ms}$).
*   **Total Events**: Tổng số lượng request.
*   **Công thức**:
    $$\text{SLI}_{\text{Latency}} = \frac{\text{Count}(\text{http\_request\_duration\_seconds} \le T)}{\text{Count}(\text{http\_request\_duration\_seconds})} \times 100\%$$

---

## 3. Khái niệm và Quản lý Error Budget (Ngân sách lỗi)

Error Budget đại diện cho mức độ không đáng tin cậy tối đa được phép xảy ra đối với dịch vụ trong một chu kỳ đo lường nhất định.

### Công thức tính toán
$$\text{Error Budget} = 100\% - \text{SLO}$$

*   Nếu mục tiêu SLO của dịch vụ là $99.9\%$, thì Error Budget là $0.1\%$. Dịch vụ được phép trả về tối đa $0.1\%$ request lỗi hoặc có thời gian phản hồi quá chậm trên tổng số request của chu kỳ.

### Bảng đối chiếu SLO và thời gian Downtime cho phép

| SLO mục tiêu | Error Budget | Downtime cho phép mỗi tuần | Downtime cho phép mỗi tháng (30 ngày) | Downtime cho phép mỗi năm (365 ngày) |
| :--- | :--- | :--- | :--- | :--- |
| **99.0%** | 1.0% | 1.68 giờ | 7.30 giờ | 3.65 ngày |
| **99.5%** | 0.5% | 50.40 phút | 3.65 giờ | 1.83 ngày |
| **99.9%** | 0.1% | 10.08 phút | 43.80 phút | 8.76 giờ |
| **99.99%** | 0.01% | 1.01 phút | 4.38 phút | 52.56 phút |

### Ý nghĩa quản trị trong SRE
Error Budget hoạt động như một cơ chế điều hòa xung đột tự nhiên giữa nhóm phát triển (Dev - muốn đẩy tính năng mới thật nhanh) và nhóm vận hành (Ops/SRE - muốn duy trì hệ thống ổn định):
*   **Còn Error Budget**: Nhóm Dev được phép triển khai (deploy) các tính năng mới nhanh hơn, chấp nhận rủi ro có lỗi phát sinh.
*   **Cạn kiệt Error Budget (Budget Exhaustion)**: Toàn bộ quy trình deploy tính năng mới bị đóng băng (deploy freeze). Nhóm Dev buộc phải chuyển hướng nguồn lực sang phối hợp cùng SRE để vá lỗi, tối ưu hiệu năng hạ tầng và cải thiện độ tin cậy nhằm khôi phục lại Error Budget cho chu kỳ tiếp theo.
