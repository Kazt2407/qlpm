# QLPM

Hệ thống quản lý phòng máy viết bằng Rails, đã được refactor sang mô hình mới gồm:

- `users`: phân quyền `admin`, `approver`, và `user`
- `rooms`: quản lý phòng máy
- `assets`: quản lý thống nhất phòng, máy tính, và thiết bị
- `borrows`: quản lý yêu cầu mượn, lịch import từ sheet, thời gian bắt đầu/kết thúc, và thời gian trả thực tế
- `work_orders`: quản lý yêu cầu bảo trì/sửa lỗi theo tài sản

Giao diện hiện dùng light theme và tách luồng rõ ràng cho `admin`, `teacher`, `student`, và bản ghi `system`.

Repo này được tổ chức như một monorepo demo: Rails app, Veyon gateway, database, Adminer, phpMyAdmin, và test runner đều được điều phối từ `docker-compose.yml` ở thư mục gốc. Không cần copy `.env.example` để chạy demo; các giá trị mặc định đã đủ cho một hệ thống local hoàn chỉnh.

## Công nghệ

- Ruby 3.4.8
- Rails 7.2
- MySQL 8
- Tailwind qua CDN trong layout

## Mô hình dữ liệu

### User

- `role`: `admin`, `approver`, `user`
- `user_type`: `admin`, `teacher`, `student`
- Có thể tạo yêu cầu mượn hoặc duyệt phiếu tùy vai trò

### Room

- Đại diện cho phòng máy vật lý
- Lưu `code`, `name`, `room_type`, `status`, `capacity`, `location`

### Asset

- Thay thế mô hình `Device` cũ
- Dùng chung cho:
  - `room`
  - `computer`
  - `device`
- Có thể gắn với `room_id` và `parent_id` để tạo cấu trúc:
  - phòng máy
  - máy tính trong phòng
  - thiết bị gắn với phòng hoặc độc lập

### Borrow

- Liên kết với `asset`
- Có hỗ trợ:
  - `borrow_source`: `manual_request`, `imported_schedule`
  - `borrower_type`: `student`, `teacher`, `system`
  - `starts_at`, `ends_at`, `returned_at`
  - `workflow_state`
  - thông tin người tạo và người duyệt
- Có phân biệt phiếu `scheduled`, `active`, `overdue`, `returned` theo thời gian thực tế.
- Chặn mượn tài sản không sẵn sàng (`inactive`, `broken`, `maintenance`) và chặn trùng lịch trên cùng tài sản.

### WorkOrder

- Liên kết với `asset`
- Theo dõi người báo lỗi, người xử lý, mức độ ưu tiên, trạng thái, hạn xử lý, chi phí và ghi chú xử lý
- Khi tạo yêu cầu mở, tài sản đang sẵn sàng sẽ chuyển sang `maintenance`; khi xử lý xong yêu cầu cuối cùng, tài sản được đồng bộ lại trạng thái sử dụng.

## Chức năng hiện có

### Đăng nhập

- Đăng nhập theo session nội bộ
- Có phân biệt quyền admin và user

### Dashboard

- Tổng quan asset, phòng, trạng thái sẵn sàng
- Phân bố asset theo phòng
- Thống kê nhanh theo nhóm người mượn
- Danh sách hoạt động gần đây

### Assets

- Danh sách và lọc theo:
  - từ khóa
  - loại asset
  - category
  - phòng
  - trạng thái
- Xem chi tiết asset
- Admin có thể tạo, sửa, xóa asset

### Borrows

- Tạo phiếu mượn theo asset
- Hỗ trợ:
  - teacher/student tạo yêu cầu thủ công
  - admin tạo bản ghi thủ công hoặc bản ghi import
  - `system` cho dữ liệu đến từ lịch sheet
- Quản lý thời gian bắt đầu, kết thúc, xác nhận trả
- Tự chặn trùng lịch trên cùng asset
- Phiếu đã duyệt trong tương lai được xem là lịch đặt trước, chưa làm tài sản chuyển sang trạng thái đang mượn.
- Trả/hủy/từ chối phiếu sẽ đồng bộ trạng thái tài sản nhưng không tự ghi đè các trạng thái vận hành thủ công như bảo trì, hỏng, hoặc ngưng dùng.
- Admin có thể import lịch bằng CSV qua màn hình preview/commit.
- Admin có thể gửi thư nhắc trả thiết bị cho phiếu quá hạn; môi trường demo mặc định ghi thư vào `tmp/mails`.
- Admin/approver có calendar tuần để xem lịch sử dụng theo phòng.

### Maintenance

- Người dùng có thể báo lỗi thiết bị từ trang chi tiết asset hoặc menu báo lỗi.
- Admin quản lý hàng chờ bảo trì, phân công người xử lý, cập nhật trạng thái, chi phí và ghi chú xử lý.
- Asset detail hiển thị link tra cứu trực tiếp để in nhãn/QR bằng công cụ bên ngoài nếu cần.

### Reports

- Chỉ admin truy cập
- Theo dõi:
  - tổng lượt mượn
  - tỷ lệ trả đúng hạn
  - phòng đang sử dụng
  - asset cần xử lý
  - xu hướng theo tháng
  - nguồn tạo phiếu
  - nhóm người mượn

### Users

- Chỉ admin truy cập
- Xem danh sách người dùng và vai trò
- Tạo, sửa, xóa, kích hoạt/vô hiệu hóa, và đặt lại mật khẩu tạm

## Routes chính

- `GET /login`
- `POST /login`
- `DELETE /logout`
- `GET /`
- `GET /assets`
- `GET /borrows`
- `GET /schedule`
- `GET /work_orders`
- `GET /reports`
- `GET /users`

## Cấu trúc thư mục chính

```text
app/
├── controllers/
│   ├── application_controller.rb
│   ├── assets_controller.rb
│   ├── borrows_controller.rb
│   ├── dashboard_controller.rb
│   ├── reports_controller.rb
│   ├── schedules_controller.rb
│   ├── sessions_controller.rb
│   ├── work_orders_controller.rb
│   ├── users_controller.rb
│   └── veyon/
├── models/
│   ├── asset.rb
│   ├── borrow.rb
│   ├── room.rb
│   ├── user.rb
│   ├── work_order.rb
│   ├── veyon_action.rb
│   └── veyon_host.rb
├── views/
│   ├── assets/
│   ├── borrows/
│   ├── dashboard/
│   ├── layouts/
│   ├── reports/
│   ├── schedules/
│   ├── sessions/
│   ├── work_orders/
│   └── users/
db/
├── migrate/
├── schema.rb
└── seeds.rb
services/
└── veyon-gateway/
```

## Cài đặt và chạy

Khuyến nghị trên Windows: dùng Docker Desktop và chạy lệnh từ PowerShell, Windows Terminal, WSL, hoặc Git Bash.

```bash
ruby bin/demo
```

Sau đó truy cập:

```text
http://localhost:3000
```

Các dịch vụ demo:

- Rails app: `http://localhost:3000`
- Veyon gateway health check: `http://localhost:8088/v1/health`
- Adminer: `http://localhost:8080`
- phpMyAdmin: `http://localhost:8081`

Dừng toàn bộ hệ thống:

```bash
docker compose down
```

Chạy trực tiếp trên máy host vẫn được hỗ trợ nếu đã có Ruby và MySQL, nhưng không phải luồng demo chính:

```bash
bundle install
bin/rails db:drop db:create db:migrate db:seed
bin/rails server
```

Với cách chạy trực tiếp, cấu hình `DB_HOST`, `DB_USERNAME`, `DB_PASSWORD`, `DB_NAME`, và `DB_TEST_NAME` trong `.env` phải khớp MySQL local.

Trên Windows, chạy các lệnh `bin/rails` và script `.sh` trong WSL hoặc Git Bash, không chạy trực tiếp trong `cmd.exe`.

## Tài khoản seed

Mật khẩu chung cho toàn bộ tài khoản seed:

```text
password123
```

Các tài khoản:

- `admin@school.edu.vn`
- `duy.approver@school.edu.vn`
- `binh.teacher@school.edu.vn`
- `an.student@school.edu.vn`

## Kiểm tra nhanh

Chạy toàn bộ test suite bằng Docker:

```bash
ruby bin/test
```

Lệnh này tự dùng MySQL trong Compose và database riêng `qlpm_test`.

Kiểm tra nhanh khi chạy trực tiếp trên host:

```bash
bin/rails db:drop db:create db:migrate db:seed
bin/rails zeitwerk:check
bin/rails test
```

## Ghi chú hiện tại

- Authentication đang là session nội bộ đơn giản, chưa phải giải pháp production-ready
- Import hiện hỗ trợ CSV; chưa hỗ trợ Excel `.xlsx` trực tiếp.
- Thư nhắc hạn dùng `MAIL_DELIVERY_METHOD=file` cho demo; đổi sang `smtp` và cấu hình `SMTP_*` khi cần gửi thật.
- Test cần MySQL đang chạy và dùng database riêng `DB_TEST_NAME`

## Hướng mở rộng tiếp theo

- Thêm import Excel `.xlsx` và rollback theo batch
- Thêm quản lý duyệt yêu cầu mượn nhiều bước
- Nâng cấp authentication cho production (session policy, reset password an toàn, rate limit)
- Bổ sung system test cho luồng UI chính
- Thêm job tự động quét phiếu quá hạn và gửi nhắc hạn định kỳ

## Tài liệu kiến trúc Veyon

- [Kiến trúc tích hợp Veyon](docs/veyon/architecture.md)
- [API contract Gateway](docs/veyon/gateway-openapi.yaml)
- [Checklist triển khai](docs/veyon/deployment-checklist.md)

### Trạng thái Rails side (đã triển khai)

- Quản lý host điều khiển: `GET /veyon/hosts`
- Màn hình điều khiển chi tiết + live framebuffer: `GET /veyon/hosts/:id`
- Gửi lệnh điều khiển: `POST /veyon/hosts/:id/execute_feature`
- Ghi audit toàn bộ thao tác vào `veyon_actions`
- Điều khiển hàng loạt theo phòng: `GET /veyon/hosts/rooms`

Phân quyền:

- `admin`: CRUD host + điều khiển
- `approver`: chỉ xem/điều khiển
- `teacher/student`: không truy cập module Veyon

### Gateway service (đã triển khai)

- Source: [services/veyon-gateway/server.mjs](services/veyon-gateway/server.mjs)
- Docker service: `veyon-gateway` trong [docker-compose.yml](/home/kazt/Projects/qlpm/docker-compose.yml)

Khởi động:

```bash
ruby bin/demo
```

Kiểm tra sức khỏe:

```bash
curl http://localhost:8088/v1/health
```

Lưu ý cấu hình bắt buộc:

- `VEYON_GATEWAY_API_KEY` phải khớp giữa Rails và gateway
- `VEYON_WEBAPI_BASE_URL` phải trỏ tới Veyon WebAPI Proxy thực tế, thường là port `11080`
- Nếu WebAPI Proxy chạy trên Docker host, mặc định `host.docker.internal:11080` đã được map qua `extra_hosts`
- Host trong màn hình Veyon của QLPM phải trỏ tới máy Windows client và `service_port` thường là `11100`
- Với `auth_logon` hoặc `auth_ldap`: cần `VEYON_AUTH_USERNAME` + `VEYON_AUTH_PASSWORD`
