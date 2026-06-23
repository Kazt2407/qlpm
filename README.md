# QLPM - Hệ thống quản lý phòng máy

QLPM là hệ thống web quản lý phòng máy cho môi trường trường học hoặc trung tâm đào tạo. Hệ thống hỗ trợ quản lý phòng máy, máy tính, thiết bị, phiếu mượn, lịch sử dụng, bảo trì, báo cáo vận hành và tích hợp điều khiển máy trạm thông qua Veyon.

Repo được tổ chức như một monorepo demo gồm ứng dụng Ruby on Rails, cơ sở dữ liệu MySQL, Veyon gateway viết bằng Node.js, Adminer, phpMyAdmin và test runner. Toàn bộ stack có thể chạy bằng Docker Compose từ thư mục gốc.

## Mục tiêu hệ thống

- Quản lý tập trung phòng máy, máy tính và thiết bị đi kèm.
- Theo dõi trạng thái tài sản: sẵn sàng, đang mượn, đang sử dụng, bảo trì, hỏng, ngưng dùng.
- Cho phép giáo viên, học sinh/sinh viên gửi yêu cầu mượn thiết bị hoặc phòng máy.
- Cho phép người duyệt và quản trị viên duyệt, từ chối, hủy, xác nhận trả và gửi nhắc hạn.
- Import lịch sử dụng từ file CSV.
- Quản lý yêu cầu bảo trì và đồng bộ trạng thái tài sản theo tiến độ xử lý.
- Cung cấp dashboard và báo cáo cho quản trị viên.
- Tích hợp tùy chọn với Veyon để xem màn hình, truy vấn session và thực thi lệnh điều khiển máy trạm.

## Tech stack sử dụng

| Nhóm                      | Công nghệ                               | Vai trò trong hệ thống                                                        |
| ------------------------- | --------------------------------------- | ----------------------------------------------------------------------------- |
| Ngôn ngữ backend chính    | Ruby 3.4.8                              | Runtime cho ứng dụng web chính                                                |
| Web framework             | Ruby on Rails 7.2.3                     | MVC, routing, controller, model, view, migration, mailer, test                |
| Web server                | Puma 6                                  | Chạy Rails app trên cổng 3000                                                 |
| Database                  | MySQL 8.4                               | Lưu users, rooms, assets, borrows, work_orders, veyon_hosts, veyon_actions    |
| ORM                       | Active Record                           | Mapping bảng MySQL thành model Ruby, validation, association, scope           |
| Template engine           | ERB                                     | Render giao diện HTML phía server                                             |
| CSS/UI                    | Tailwind CSS qua CDN, Be Vietnam Pro    | Xây dựng giao diện quản trị light theme bằng class utility                    |
| Authentication            | Rails session, bcrypt                   | Đăng nhập nội bộ, lưu `user_id` trong session, băm mật khẩu                   |
| Import dữ liệu            | Ruby CSV                                | Đọc, preview và commit lịch mượn từ file CSV                                  |
| Email                     | Action Mailer                           | Gửi hoặc ghi file email nhắc trả thiết bị                                     |
| Veyon gateway             | Node.js native HTTP server              | Proxy an toàn từ Rails tới Veyon WebAPI                                       |
| Tích hợp Veyon phía Rails | `Veyon::GatewayClient` dùng `Net::HTTP` | Rails gọi gateway bằng API key để lấy framebuffer, user/session, chạy feature |
| Container                 | Docker, Docker Compose                  | Dựng Rails app, MySQL, gateway, Adminer, phpMyAdmin, test runner              |
| Test                      | Minitest                                | Test model, service và integration workflow                                   |
| Dev DB tools              | Adminer, phpMyAdmin                     | Kiểm tra dữ liệu MySQL khi chạy local                                         |
| Cấu hình môi trường       | ENV, dotenv-rails                       | Đọc biến môi trường cho database, mail, pagination, Veyon                     |

## Kiến trúc tổng thể

```text
Browser
  |
  | HTTP
  v
Ruby on Rails app (Puma, port 3000)
  |
  | Active Record + mysql2
  v
MySQL 8.4

Rails app
  |
  | Action Mailer
  v
tmp/mails hoặc SMTP server

Rails app
  |
  | Net::HTTP + X-API-Key
  v
Node.js Veyon Gateway (port 8088)
  |
  | HTTP tới Veyon WebAPI
  v
Veyon WebAPI trên máy host hoặc mạng nội bộ
  |
  v
Máy trạm phòng máy

Adminer/phpMyAdmin
  |
  v
MySQL 8.4
```

## Cách các thành phần kết nối với nhau

1. Người dùng truy cập giao diện web qua trình duyệt tại `http://localhost:3000`.
2. Puma nhận request và chuyển vào Rails router trong `config/routes.rb`.
3. Router ánh xạ request tới controller tương ứng như `AssetsController`, `BorrowsController`, `ReportsController`, `Veyon::HostsController`.
4. `ApplicationController` kiểm tra đăng nhập, phân quyền và chuẩn bị dữ liệu sidebar.
5. Controller gọi model Active Record hoặc service object để xử lý nghiệp vụ.
6. Active Record dùng gem `mysql2` để đọc/ghi dữ liệu trong MySQL.
7. View ERB render HTML, dùng Tailwind CSS từ CDN để tạo giao diện.
8. Với email nhắc hạn, Rails gọi `BorrowMailer`; môi trường demo mặc định ghi email vào `tmp/mails`, production có thể cấu hình SMTP.
9. Với chức năng điều khiển phòng máy, Rails gọi `Veyon::GatewayClient`; client này gửi HTTP request đến service `veyon-gateway`.
10. Veyon gateway xác thực bằng `X-API-Key`, mở hoặc tái sử dụng phiên kết nối với Veyon WebAPI, sau đó proxy lệnh tới máy trạm.
11. Docker Compose điều phối các service, truyền biến môi trường và tạo network nội bộ để Rails có thể gọi MySQL bằng hostname `mysql` và gateway bằng hostname `veyon-gateway`.

## Ruby on Rails trong dự án

Ruby on Rails là framework trung tâm của hệ thống. Trong repo này, Rails không chỉ dùng để tạo web page mà còn chịu trách nhiệm tổ chức nghiệp vụ, truy cập dữ liệu, bảo mật request, gửi email, chạy test và quản lý cấu trúc database.

### Vai trò của Rails MVC

Rails app được chia theo mô hình MVC:

- Model: nằm trong `app/models`, đại diện cho dữ liệu và quy tắc nghiệp vụ gắn trực tiếp với dữ liệu.
- View: nằm trong `app/views`, render HTML bằng ERB.
- Controller: nằm trong `app/controllers`, nhận request, kiểm tra quyền, gọi model/service và chọn view trả về.

Ví dụ luồng tạo phiếu mượn:

```text
POST /borrows
  -> config/routes.rb
  -> BorrowsController#create
  -> BorrowLifecycleService.apply_defaults!
  -> Borrow model validate dữ liệu
  -> Active Record lưu vào bảng borrows
  -> Redirect hoặc render form lỗi
```

### Routing

File `config/routes.rb` định nghĩa URL public của hệ thống:

- `/login`, `/logout`: đăng nhập và đăng xuất.
- `/`: dashboard.
- `/assets`: quản lý phòng, máy tính, thiết bị.
- `/rooms`: quản lý phòng máy vật lý.
- `/borrows`: quản lý phiếu mượn, duyệt, hủy, trả, nhắc hạn.
- `/schedule`: lịch sử dụng theo tuần.
- `/borrow_import`: preview và commit import CSV.
- `/work_orders`: bảo trì, sửa lỗi.
- `/reports`: báo cáo.
- `/users`: quản lý người dùng.
- `/veyon/hosts`: quản lý host và thao tác điều khiển Veyon.

### Controller và phân quyền

`ApplicationController` là lớp nền cho toàn bộ controller:

- Bắt buộc đăng nhập bằng `before_action :require_login`.
- Lấy người dùng hiện tại qua `session[:user_id]`.
- Cung cấp helper `current_user`, `can_manage_system?`, `can_review_borrows?`, `requester_user?`.
- Chặn quyền admin, quyền duyệt và quyền gửi yêu cầu bằng các hàm `require_admin!`, `require_borrow_reviewer!`, `require_request_submission_access!`.
- Chuẩn hóa phân trang qua `paginate_scope`.

Hệ thống có 3 vai trò chính:

- `admin`: quản trị toàn hệ thống, quản lý users, assets, rooms, reports, bảo trì, Veyon.
- `approver`: duyệt phiếu mượn và có thể dùng một số thao tác Veyon được cấp quyền.
- `user`: người dùng thường, gồm `teacher` và `student`, có thể gửi yêu cầu mượn và báo lỗi.

### Active Record, model và database

Active Record giúp model Ruby kết nối trực tiếp tới bảng MySQL. Các model chính:

- `User`: tài khoản, vai trò, loại người dùng, mật khẩu bcrypt.
- `Room`: phòng máy vật lý.
- `Asset`: tài sản dùng chung cho phòng máy, máy tính và thiết bị.
- `Borrow`: phiếu mượn, lịch sử dụng, import schedule, trạng thái workflow.
- `WorkOrder`: yêu cầu bảo trì, phân công xử lý, chi phí và ghi chú khắc phục.
- `VeyonHost`: thông tin host Veyon gắn với máy tính.
- `VeyonAction`: lịch sử lệnh Veyon đã thực thi.

Rails migration trong `db/migrate` mô tả cách thay đổi schema theo thời gian. File `db/schema.rb` là snapshot schema hiện tại, dùng để tạo nhanh database test hoặc development.

### Validation và association

Rails model chứa các ràng buộc nghiệp vụ quan trọng:

- `Asset` yêu cầu `code` duy nhất, `name` bắt buộc, `asset_type`, `category`, `status` thuộc danh sách hợp lệ.
- `Borrow` kiểm tra thời gian kết thúc sau thời gian bắt đầu.
- `Borrow` chặn mượn tài sản không sẵn sàng.
- `Borrow` chặn trùng lịch trên cùng tài sản.
- `User` chuẩn hóa email, kiểm tra email duy nhất và dùng `has_secure_password`.

Các association giúp Rails truy vấn quan hệ dễ đọc hơn:

- `Asset has_many :borrows`
- `Asset has_many :work_orders`
- `Asset belongs_to :room`
- `Asset belongs_to :parent`
- `User has_many :created_borrows`
- `Borrow belongs_to :asset`
- `WorkOrder belongs_to :asset`

### Service object

Dự án tách nghiệp vụ phức tạp khỏi controller bằng service object:

- `BorrowLifecycleService`: áp dụng mặc định theo vai trò, duyệt phiếu, từ chối, hủy, xác nhận trả, gửi nhắc hạn và đồng bộ trạng thái tài sản.
- `BorrowImporter`: đọc CSV, preview lỗi từng dòng, commit các dòng hợp lệ vào database.
- `Veyon::GatewayClient`: đóng gói giao tiếp từ Rails tới Veyon gateway.

Cách tách này giúp controller ngắn hơn, dễ test hơn và tránh nhúng logic trạng thái trực tiếp trong view.

### View và giao diện

Ứng dụng dùng server-rendered HTML:

- ERB template nằm trong `app/views`.
- Layout chính ở `app/views/layouts/application.html.erb`.
- Tailwind CSS được tải qua CDN trong layout.
- Font Be Vietnam Pro được dùng để tối ưu giao diện tiếng Việt.
- Rails CSRF meta tag và CSP meta tag được bật trong layout.

Dù `Gemfile` có `turbo-rails`, `stimulus-rails` và `importmap-rails`, giao diện hiện tại chủ yếu là Rails server-rendered HTML truyền thống.

### Action Mailer

`BorrowMailer` dùng để gửi email nhắc trả thiết bị. Cấu hình mail nằm trong `config/environments/development.rb` và `config/environments/production.rb`.

- Development mặc định: `MAIL_DELIVERY_METHOD=file`, email được ghi vào `tmp/mails`.
- Production mặc định: `MAIL_DELIVERY_METHOD=smtp`, cấu hình bằng các biến `SMTP_*`.

### Test trong Rails

Test dùng Minitest, nằm trong thư mục `test`:

- `test/models`: test model và service.
- `test/integration`: test workflow HTTP từ góc nhìn người dùng.
- `test/test_helper.rb`: cấu hình test chung.

Lệnh chạy test bằng Docker:

```bash
ruby bin/test
```

## Mô hình dữ liệu nghiệp vụ

### User

Người dùng có:

- `role`: `admin`, `approver`, `user`.
- `user_type`: `admin`, `teacher`, `student`.
- `active`: bật hoặc vô hiệu hóa tài khoản.
- `password_digest`: mật khẩu băm bằng bcrypt.

### Room

Đại diện cho phòng máy vật lý:

- Mã phòng, tên phòng.
- Loại phòng.
- Trạng thái.
- Sức chứa.
- Vị trí.
- Ghi chú.

### Asset

`Asset` là model tài sản thống nhất, thay thế cách tách riêng phòng, máy tính và thiết bị:

- `asset_type = room`: phòng máy như một đối tượng có thể được lên lịch.
- `asset_type = computer`: máy tính trong phòng.
- `asset_type = device`: thiết bị như màn hình, chuột, bàn phím, máy chiếu, máy in.

Asset có thể liên kết:

- Với `Room` qua `room_id`.
- Với asset cha qua `parent_id`, ví dụ máy tính thuộc asset phòng máy.
- Với `VeyonHost` nếu là máy tính có thể điều khiển.

### Borrow

Phiếu mượn hoặc lịch sử dụng có:

- Tài sản được mượn.
- Người tạo phiếu.
- Người duyệt.
- Nguồn phiếu: `manual_request` hoặc `imported_schedule`.
- Nhóm người mượn: `system`, `teacher`, `student`.
- Thời gian bắt đầu, kết thúc, thời gian trả thực tế.
- Trạng thái workflow: `pending`, `approved`, `rejected`, `active`, `returned`, `cancelled`, `overdue`.

Trạng thái hiển thị được tính theo thời gian thực tế:

- Chưa tới giờ: đã lên lịch.
- Đang trong khoảng thời gian mượn: đang mượn hoặc đang sử dụng.
- Quá `ends_at` và chưa trả: quá hạn.
- Có `returned_at`: đã trả.

### WorkOrder

Yêu cầu bảo trì có:

- Tài sản cần xử lý.
- Người báo lỗi.
- Người được phân công.
- Tiêu đề và mô tả lỗi.
- Mức ưu tiên.
- Trạng thái xử lý.
- Hạn xử lý, chi phí, thời gian hoàn tất và ghi chú khắc phục.

### VeyonHost và VeyonAction

- `VeyonHost` lưu host, port, trạng thái bật/tắt và metadata của máy tính có thể điều khiển.
- `VeyonAction` lưu lịch sử lệnh điều khiển, payload gửi đi, phản hồi nhận về và lỗi nếu có.

## Chức năng chính

### Đăng nhập và phân quyền

- Đăng nhập bằng email và mật khẩu.
- Session nội bộ của Rails dùng để duy trì trạng thái đăng nhập.
- Sidebar và route được điều chỉnh theo vai trò.
- Tài khoản bị vô hiệu hóa không thể tiếp tục sử dụng session cũ.

### Dashboard

Dashboard cho quản trị viên hiển thị:

- Tổng số tài sản.
- Tổng số phòng.
- Tài sản sẵn sàng.
- Phiếu đang mở.
- Bảo trì đang mở.
- Hoạt động gần đây và các chỉ số vận hành.

### Quản lý tài sản

Admin có thể:

- Tạo, sửa, xóa asset.
- Lọc theo từ khóa, loại tài sản, category, phòng, trạng thái.
- Xem chi tiết thông tin cấu hình máy, bảo hành, serial, IP, ghi chú.
- Theo dõi lịch mượn và bảo trì liên quan tới tài sản.

### Quản lý phòng máy

Admin có thể quản lý phòng máy vật lý, sức chứa, vị trí và trạng thái. Phòng máy cũng có thể được biểu diễn dưới dạng `Asset` để tham gia lịch sử dụng.

### Phiếu mượn và lịch sử dụng

Hệ thống hỗ trợ:

- Người dùng tạo yêu cầu mượn thủ công.
- Admin tạo bản ghi thủ công hoặc bản ghi import.
- Người duyệt duyệt hoặc từ chối phiếu.
- Admin xác nhận trả, hủy phiếu, gửi email nhắc hạn.
- Chặn mượn tài sản đang hỏng, bảo trì, ngưng dùng.
- Chặn trùng lịch trên cùng tài sản.
- Đồng bộ trạng thái tài sản khi phiếu bắt đầu, trả, hủy hoặc bị từ chối.

### Import CSV

Admin có thể import lịch sử dụng từ CSV qua luồng:

1. Upload CSV.
2. `BorrowImporter` đọc file và kiểm tra header bắt buộc.
3. Mỗi dòng được preview kèm lỗi nếu có.
4. Admin commit các dòng hợp lệ.
5. Hệ thống tạo `Borrow` với `borrow_source = imported_schedule`.

Các cột bắt buộc:

```text
asset_code,borrower_name,starts_at,ends_at
```

### Bảo trì

Người dùng có thể báo lỗi thiết bị. Admin quản lý hàng chờ bảo trì:

- Gán người xử lý.
- Cập nhật trạng thái.
- Đặt mức ưu tiên và hạn xử lý.
- Ghi nhận chi phí và ghi chú khắc phục.
- Đồng bộ trạng thái tài sản khi có hoặc hết yêu cầu bảo trì mở.

### Báo cáo

Khu vực báo cáo dành cho admin:

- Tổng lượt mượn.
- Tỷ lệ trả đúng hạn.
- Phòng và tài sản đang sử dụng.
- Tài sản cần chú ý.
- Xu hướng theo tháng.
- Nguồn tạo phiếu.
- Nhóm người mượn.

### Tích hợp Veyon

Tích hợp Veyon là tùy chọn và mặc định tắt bằng `VEYON_ENABLED=false`.

Khi bật, luồng hoạt động là:

1. Admin hoặc approver truy cập khu vực điều khiển phòng máy.
2. Rails đọc `VeyonHost` gắn với asset máy tính.
3. Rails gọi `Veyon::GatewayClient`.
4. Gateway client gửi request tới Node.js Veyon gateway kèm `X-API-Key`.
5. Gateway mở hoặc tái sử dụng connection tới Veyon WebAPI.
6. Gateway gọi Veyon WebAPI để lấy framebuffer, user info, session info hoặc chạy feature.
7. Rails lưu kết quả thao tác vào `VeyonAction`.

Các feature hỗ trợ:

- `screen_lock`
- `input_devices_lock`
- `user_logoff`
- `reboot`
- `power_down`
- `text_message`
- `open_website`
- `start_app`

Admin và approver có thể được cấp danh sách feature khác nhau qua biến môi trường:

- `VEYON_ALLOWED_FEATURES_ADMIN`
- `VEYON_ALLOWED_FEATURES_APPROVER`

## Docker Compose services

`docker-compose.yml` định nghĩa các service:

| Service         | Vai trò                           | Cổng mặc định |
| --------------- | --------------------------------- | ------------- |
| `mysql`         | MySQL 8.4, database chính và test | `3306`        |
| `app`           | Rails app chạy Puma               | `3000`        |
| `test`          | Container chạy test suite         | Không expose  |
| `veyon-gateway` | Node.js proxy tới Veyon WebAPI    | `8088`        |
| `adminer`       | DB admin UI gọn nhẹ               | `8080`        |
| `phpmyadmin`    | DB admin UI đầy đủ hơn            | `8081`        |

Các volume chính:

- `mysql_data`: dữ liệu MySQL.
- `bundle_cache`: cache gem Ruby.
- `app_storage`: thư mục `storage` của Rails.
- `app_tmp`: thư mục `tmp` của Rails.
- `app_log`: log Rails.

## Cấu trúc thư mục

```text
app/
  controllers/       Controller Rails
  helpers/           Helper cho view
  mailers/           Action Mailer
  models/            Active Record model
  services/          Service object nghiệp vụ
  views/             ERB template
bin/
  demo               Chạy toàn bộ demo stack
  test               Chạy test bằng Docker
config/
  routes.rb          Khai báo route
  database.yml       Cấu hình MySQL
  environments/      Cấu hình development/test/production
  initializers/      Cấu hình ứng dụng
db/
  migrate/           Migration
  schema.rb          Snapshot schema
  seeds.rb           Dữ liệu mẫu
docker/
  mysql/init/        Script khởi tạo database phụ
docs/
  veyon/             Tài liệu kiến trúc và OpenAPI cho Veyon gateway
services/
  veyon-gateway/     Node.js gateway service
test/
  integration/       Test workflow HTTP
  models/            Test model/service
```

## Yêu cầu môi trường

Khuyến nghị chạy bằng Docker:

- Docker Desktop hoặc Docker Engine.
- Docker Compose.
- Ruby trên máy host để chạy script `ruby bin/demo` và `ruby bin/test`.

Nếu chạy trực tiếp không dùng Docker:

- Ruby 3.4.8.
- Bundler 4.0.8.
- MySQL 8.x.
- Các biến `DB_*` trỏ đúng MySQL local.

## Cài đặt và chạy demo bằng Docker

Không bắt buộc copy `.env.example` để chạy demo vì `docker-compose.yml` đã có giá trị mặc định.

Chạy toàn bộ hệ thống:

```bash
ruby bin/demo
```

Sau khi build xong, truy cập:

```text
Rails app:       http://localhost:3000
Veyon gateway:   http://localhost:8088/v1/health
Adminer:         http://localhost:8080
phpMyAdmin:      http://localhost:8081
```

Dừng toàn bộ hệ thống:

```bash
docker compose down
```

Dừng và xóa cả volume dữ liệu:

```bash
docker compose down -v
```

## Tài khoản seed

Mật khẩu chung:

```text
password123
```

Tài khoản mẫu:

| Vai trò            | Email                        |
| ------------------ | ---------------------------- |
| Admin              | `admin@school.edu.vn`        |
| Người duyệt        | `duy.approver@school.edu.vn` |
| Giáo viên          | `binh.teacher@school.edu.vn` |
| Học sinh/sinh viên | `an.student@school.edu.vn`   |

## Chạy test

Chạy toàn bộ test suite bằng Docker:

```bash
ruby bin/test
```

Lệnh này dùng service `test` trong Docker Compose, kết nối tới MySQL và database `qlpm_test`.

Chạy test trực tiếp trên host:

```bash
bundle install
bin/rails db:prepare
bin/rails test
```

Kiểm tra autoload của Rails:

```bash
bin/rails zeitwerk:check
```

## Chạy trực tiếp trên máy host

Luồng này phù hợp khi máy đã có Ruby và MySQL local:

```bash
bundle install
bin/rails db:drop db:create db:migrate db:seed
bin/rails server
```

Các biến quan trọng trong `.env` hoặc shell:

```text
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USERNAME=qlpm
DB_PASSWORD=qlpm
DB_NAME=qlpm
DB_TEST_NAME=qlpm_test
```

Trên Windows, nên chạy các lệnh `bin/rails`, `bin/demo`, `bin/test` trong WSL hoặc Git Bash.

## Biến môi trường quan trọng

### Rails và database

- `RAILS_ENV`: môi trường Rails, mặc định `development`.
- `RAILS_MAX_THREADS`: số thread Puma và pool Active Record.
- `APP_HOST`, `APP_PORT`: host và port dùng cho URL trong app/mail.
- `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`, `DB_NAME`, `DB_TEST_NAME`: cấu hình MySQL.

### Cấu hình nghiệp vụ

- `APP_PAGINATION_DEFAULT_PER_PAGE`: số dòng mặc định mỗi trang.
- `APP_PAGINATION_MAX_PER_PAGE`: giới hạn số dòng mỗi trang.
- `APP_BORROW_DEFAULT_DURATION_MINUTES`: thời lượng mượn mặc định.
- `APP_REPORT_TOP_BORROWERS_LIMIT`: số borrower đứng đầu trong báo cáo.
- `APP_REPORT_ATTENTION_ASSETS_LIMIT`: số tài sản cần chú ý trong báo cáo.
- `APP_REPORT_MONTHS_LOOKBACK`: số tháng dùng để tính xu hướng.

### Mail

- `MAIL_FROM`: địa chỉ gửi mặc định.
- `MAIL_DELIVERY_METHOD`: `file` hoặc `smtp`.
- `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_DOMAIN`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_AUTHENTICATION`, `SMTP_ENABLE_STARTTLS_AUTO`: cấu hình SMTP.

### Veyon

- `VEYON_ENABLED`: bật/tắt tích hợp Veyon.
- `VEYON_GATEWAY_BASE_URL`: URL gateway để Rails gọi.
- `VEYON_GATEWAY_API_KEY`: API key giữa Rails và gateway.
- `VEYON_WEBAPI_BASE_URL`: URL Veyon WebAPI mà gateway gọi tiếp.
- `VEYON_DEFAULT_AUTH_METHOD`: phương thức xác thực mặc định.
- `VEYON_AUTH_USERNAME`, `VEYON_AUTH_PASSWORD`, `VEYON_AUTH_SIMPLE_PASSWORD`, `VEYON_AUTH_KEYNAME`, `VEYON_AUTH_KEYDATA`: thông tin xác thực Veyon.
- `VEYON_FRAMEBUFFER_FORMAT`, `VEYON_FRAMEBUFFER_WIDTH`, `VEYON_FRAMEBUFFER_HEIGHT`, `VEYON_FRAMEBUFFER_JPEG_QUALITY`, `VEYON_FRAMEBUFFER_POLL_INTERVAL_MS`: cấu hình ảnh màn hình.

## Database và migration

Tạo hoặc cập nhật database:

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

Reset database development:

```bash
bin/rails db:drop db:create db:migrate db:seed
```

Khi thay đổi model cần thay đổi schema, tạo migration mới:

```bash
bin/rails generate migration TenMigration
```

Sau khi migrate, kiểm tra `db/schema.rb` để đảm bảo schema phản ánh đúng thay đổi.

## Ghi chú triển khai

- Authentication hiện là cơ chế session nội bộ, phù hợp demo hoặc môi trường kiểm soát. Nếu triển khai production thật, nên bổ sung chính sách mật khẩu, giới hạn login sai, audit log và HTTPS bắt buộc.
- Production đang bật `config.force_ssl = true`, cần chạy sau reverse proxy hoặc cấu hình SSL phù hợp.
- Không commit `.env`, log, tmp, database local hoặc artifact report.
- Veyon mặc định tắt. Chỉ bật khi đã có Veyon WebAPI và thông tin xác thực hợp lệ.
- SMTP cần được cấu hình rõ nếu muốn gửi email thật.
- Import hiện hỗ trợ CSV, chưa hỗ trợ Excel `.xlsx` trực tiếp.

## Lệnh hữu ích

```bash
# Chạy demo
ruby bin/demo

# Xem log Rails container
docker compose logs -f app

# Mở Rails console trong container
docker compose exec app ruby bin/rails console

# Chạy migration trong container
docker compose exec app ruby bin/rails db:migrate

# Seed lại dữ liệu trong container
docker compose exec app ruby bin/rails db:seed

# Chạy test
ruby bin/test

# Dừng stack
docker compose down
```
