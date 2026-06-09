# Chuyên đề 04: Cơ chế Cảnh báo Nâng cao Multi-window Multi-burn-rate Alerting

Cảnh báo dựa trên ngưỡng tĩnh truyền thống thường gây ra hiện tượng Alert Fatigue (nhiễu loạn cảnh báo do các đỉnh đột biến ngắn hạn) hoặc cảnh báo quá trễ. Để khắc phục điều này, Google SRE giới thiệu phương pháp cảnh báo dựa trên tốc độ tiêu thụ Error Budget (Burn Rate).

---

## 1. Khái niệm Burn Rate (Tốc độ tiêu thụ ngân sách lỗi)

Burn Rate định nghĩa tốc độ dịch vụ đang tiêu thụ Error Budget của nó nhanh như thế nào.

*   **Burn Rate = 1**: Dịch vụ tiêu thụ chính xác $100\%$ Error Budget trong toàn bộ chu kỳ thiết lập (ví dụ: 30 ngày). Điều này có nghĩa là hệ thống đạt vừa khít mục tiêu SLO cuối chu kỳ.
*   **Burn Rate = 2**: Dịch vụ tiêu thụ hết toàn bộ Error Budget nhanh gấp đôi, tương đương tiêu thụ sạch ngân sách lỗi trong 15 ngày.
*   **Burn Rate = 14.4**: Dịch vụ tiêu thụ hết Error Budget trong vòng 50 giờ (khoảng 2 ngày).
*   **Burn Rate = 36**: Dịch vụ tiêu thụ sạch Error Budget chỉ trong vòng 20 giờ.

Công thức tính tỉ lệ phần trăm Error Budget bị tiêu thụ trong một khoảng thời gian $H$ (giờ) với Burn Rate $B$:

$$\text{Error Budget Consumed (\%)} = \frac{B \times H}{720\text{ hours (30 days)}} \times 100\%$$

---

## 2. Tại sao cần Multi-window Multi-burn-rate Alerting?

Nếu thiết lập cảnh báo chỉ dựa trên một khung thời gian đơn lẻ (Single Window), hệ thống sẽ gặp phải bài toán đánh đổi không tối ưu:
*   Nếu dùng khung thời gian ngắn (ví dụ: 5 phút), cảnh báo báo lỗi nhanh nhưng rất dễ bị nhiễu do các spike tự phục hồi.
*   Nếu dùng khung thời gian dài (ví dụ: 24 giờ), hệ thống sẽ lọc nhiễu tốt nhưng thời gian phát hiện lỗi (detection time) quá chậm, dẫn đến dịch vụ sập rất lâu trước khi kỹ sư nhận được tin nhắn.

Để giải quyết triệt để, Google SRE khuyến nghị cơ chế **Multi-window Multi-burn-rate Alerting** kết hợp đồng thời hai khung thời gian: **Long Window** (Khung thời gian dài để đảm bảo độ chính xác) và **Short Window** (Khung thời gian ngắn để kiểm tra lỗi còn đang tiếp diễn hay đã tự hết).

---

## 3. Kiến trúc Cảnh báo Đa khung thời gian Tiêu chuẩn

Hệ thống giám sát sẽ theo dõi song song các điều kiện cảnh báo sau:

```text
             [ Metrics Data Stream ]
                       │
      ┌────────────────┴────────────────┐
      ▼                                 ▼
[ Fast Burn Rate Checker ]        [ Slow Burn Rate Checker ]
- Long window: 1 Hour             - Long window: 6 Hours
- Short window: 5 Mins            - Short window: 30 Mins
- Burn Rate Threshold: 14.4       - Burn Rate Threshold: 6.0
      │                                 │
      ▼ (If Both Windows Violate)       ▼ (If Both Windows Violate)
[ Page SRE (High Priority) ]     [ Ticket SRE (Low Priority) ]
```

### Fast Burn Rate (Cảnh báo lỗi sập hệ thống khẩn cấp)
*   **Mục tiêu**: Phát hiện các sự cố nghiêm trọng làm cạn kiệt Error Budget nhanh chóng (ví dụ: database ngắt kết nối, lỗi code deploy làm crash ứng dụng).
*   **Tham số cấu hình**:
    *   **Burn Rate Threshold**: $14.4$ (tiêu thụ mất $2\%$ Error Budget trong 1 giờ).
    *   **Long Window**: $1\text{ giờ}$.
    *   **Short Window**: $5\text{ phút}$.
*   **Cơ chế kích hoạt**: Cảnh báo chỉ được gửi đi khi và chỉ khi:
    1.  Tỉ lệ lỗi trung bình trong $1\text{ giờ}$ qua vượt ngưỡng tương đương Burn Rate $14.4$.
    2.  **VÀ** tỉ lệ lỗi trong $5\text{ phút}$ gần nhất cũng vượt ngưỡng tương đương Burn Rate $14.4$.
*   **Reset Time**: Nếu sự cố đã được tự động khắc phục, Short Window ($5\text{ phút}$) sẽ hạ thấp tỉ lệ lỗi xuống dưới ngưỡng ngay lập tức, tự động đóng (resolve) cảnh báo mà không bắt kỹ sư phải đợi hết $1\text{ giờ}$ của Long Window.

### Slow Burn Rate (Cảnh báo lỗi rò rỉ âm thầm)
*   **Mục tiêu**: Phát hiện các lỗi nhỏ kéo dài liên tục làm bào mòn ngân sách lỗi theo thời gian (ví dụ: rò rỉ bộ nhớ, phản hồi API chậm dần).
*   **Tham số cấu hình**:
    *   **Burn Rate Threshold**: $6.0$ (tiêu thụ mất $5\%$ Error Budget trong 6 giờ).
    *   **Long Window**: $6\text{ giờ}$.
    *   **Short Window**: $30\text{ phút}$.
*   **Cơ chế kích hoạt**: Tương tự như trên, kích hoạt khi cả trung bình $6\text{ giờ}$ qua và $30\text{ phút}$ gần nhất đều vượt ngưỡng tiêu thụ tương đương Burn Rate $6.0$. Cảnh báo này thường có độ ưu tiên thấp hơn (gửi ticket Jira/Email thay vì gọi điện thoại đánh thức kỹ sư trực ca SRE).
