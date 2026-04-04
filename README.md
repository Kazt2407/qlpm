# QLPM

Hệ thống quản lý phòng máy viết bằng Rails, đã được refactor sang mô hình mới gồm:

- `users`: phân quyền `admin` và `user`
- `rooms`: quản lý phòng máy
- `assets`: quản lý thống nhất phòng, máy tính, và thiết bị
- `borrows`: quản lý yêu cầu mượn, lịch import từ sheet, thời gian bắt đầu/kết thúc, và thời gian trả thực tế

Giao diện hiện dùng light theme và tách luồng rõ ràng cho `admin`, `teacher`, `student`, và bản ghi `system`.

## Công nghệ

- Ruby 3.4.8
- Rails 7.2
- SQLite3
- Tailwind qua CDN trong layout

## Mô hình dữ liệu

### User

- `role`: `admin`, `user`
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

## Routes chính

- `GET /login`
- `POST /login`
- `DELETE /logout`
- `GET /`
- `GET /assets`
- `GET /borrows`
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
│   ├── sessions_controller.rb
│   └── users_controller.rb
├── models/
│   ├── asset.rb
│   ├── borrow.rb
│   ├── room.rb
│   └── user.rb
├── views/
│   ├── assets/
│   ├── borrows/
│   ├── dashboard/
│   ├── layouts/
│   ├── reports/
│   ├── sessions/
│   └── users/
db/
├── migrate/
├── schema.rb
└── seeds.rb
```

## Cài đặt và chạy

```bash
bundle install
bin/rails db:drop db:create db:migrate db:seed
bin/rails server
```

Sau đó truy cập:

```text
http://localhost:3000
```

## Tài khoản seed

Mật khẩu chung cho toàn bộ tài khoản seed:

```text
password123
```

Các tài khoản:

- `admin@school.edu.vn`
- `binh.teacher@school.edu.vn`
- `an.student@school.edu.vn`

## Kiểm tra nhanh

Các lệnh đã dùng để xác nhận project hiện chạy ổn:

```bash
bin/rails db:drop db:create db:migrate db:seed
bin/rails zeitwerk:check
```

## Ghi chú hiện tại

- Authentication đang là session nội bộ đơn giản, chưa phải giải pháp production-ready
- Chưa có import sheet thật, mới dừng ở cấu trúc dữ liệu và bản ghi mẫu `imported_schedule`
- Chưa có CRUD đầy đủ cho `users` và `rooms`
- Chưa có test suite cho luồng mới

## Hướng mở rộng tiếp theo

- Thêm import Excel/CSV cho lịch phòng máy
- Thêm CRUD riêng cho `rooms`
- Thêm quản lý duyệt yêu cầu mượn nhiều bước
- Nâng cấp authentication và password hashing
- Bổ sung test model, controller, và system test
