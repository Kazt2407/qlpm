# Checklist triển khai Veyon cho QLPM

## A. Hạ tầng mạng
- Đảm bảo QLPM app/gateway truy cập được LAN của máy trạm.
- Mở firewall theo hướng cần thiết.
- Đồng bộ DNS hoặc mapping host/IP cho danh sách máy.
- Phân biệt rõ `11080` là port WebAPI Proxy, còn `11100` là port Veyon Service trên từng Windows client.

## B. Veyon trên máy trạm
- Cài Veyon Service trên tất cả client cần điều khiển.
- Bật Service autostart.
- Xác nhận port Veyon server mặc định `11100` lắng nghe đúng.
- Đồng bộ cấu hình Veyon giữa các máy.

## C. WebAPI Proxy
- Bật plugin WebAPI (advanced view).
- Cấu hình port WebAPI (mặc định `11080`).
- Đặt `ConnectionIdleTimeout`, `ConnectionLifetime`, `MaxOpenConnections` phù hợp.
- Cân nhắc bật HTTPS/TLS 1.3 và cấp cert hợp lệ.

## D. Gateway
- Cấu hình secret `X-API-Key` giữa Rails và Gateway.
- Cấu hình timeout/retry/circuit-breaker.
- Bật audit log và log cấu trúc JSON.
- Bật cache framebuffer ngắn hạn.
- Kiểm tra biến môi trường chính:
  - `VEYON_WEBAPI_BASE_URL`
  - `VEYON_DEFAULT_AUTH_METHOD`
  - `VEYON_AUTH_USERNAME`/`VEYON_AUTH_PASSWORD` (hoặc phương thức auth tương ứng)
  - `VEYON_WEBAPI_INSECURE_SKIP_TLS_VERIFY` (chỉ bật ở môi trường lab/test)

## E. QLPM Rails
- Map `assets` với `veyon_hosts`.
- Trong mỗi host mapping, nhập `host` là DNS/IP của Windows client và `service_port` là port Veyon Service, mặc định `11100`.
- Chỉ `admin/approver` có endpoint thao tác điều khiển.
- Ghi `veyon_actions` cho mọi lệnh điều khiển.
- Ẩn toàn bộ chức năng điều khiển khỏi `teacher/student`.

## F. Kiểm thử bắt buộc
- Approver lock/unlock 1 máy thành công.
- Approver gửi text message 1 máy thành công.
- Teacher/student không gọi được API điều khiển (403).
- Mất kết nối 1 host không ảnh hưởng host khác.
- Dashboard điều khiển tải 30 thumbnail đầu < 3 giây (LAN demo).
