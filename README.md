<<<<<<< HEAD
# PhòngMáy Pro – Hệ thống Quản lý Thiết bị Phòng Máy

Rails 7 application chuyển đổi từ 5 HTML views sang full MVC.

---

## Yêu cầu hệ thống

- Ruby 3.2+
- Rails 7.1
- SQLite3

---

## Cài đặt & khởi chạy

```bash
# 1. Clone hoặc giải nén project
cd phonemay_app

# 2. Cài đặt gems
bundle install

# 3. Thiết lập database
rails db:create
rails db:migrate
rails db:seed      # tạo dữ liệu mẫu

# 4. Khởi chạy server
rails server
# Truy cập: http://localhost:3000
```

---

## Cấu trúc ứng dụng

```
app/
├── controllers/
│   ├── application_controller.rb   # base controller, sidebar counts
│   ├── dashboard_controller.rb     # View 1: Tổng quan
│   ├── devices_controller.rb       # View 2 & 4: Danh sách + Chi tiết
│   ├── borrows_controller.rb       # View 3: Mượn – Trả
│   └── reports_controller.rb       # View 5: Báo cáo
│
├── models/
│   ├── device.rb                   # Thiết bị: validations, scopes, helpers
│   └── borrow.rb                   # Phiếu mượn: logic trả, quá hạn
│
├── views/
│   ├── layouts/application.html.erb  # Sidebar chung
│   ├── dashboard/index.html.erb
│   ├── devices/{index,show,new,edit,_form}.html.erb
│   ├── borrows/{index,new,_form}.html.erb
│   └── reports/index.html.erb
│
└── helpers/
    └── application_helper.rb       # status_badge, vn_date, pct_width...
```

---

## Mapping HTML → Rails

| HTML file              | Rails route       | Controller#action       |
|------------------------|-------------------|-------------------------|
| `01_dashboard.html`    | `GET /`           | `dashboard#index`       |
| `02_device_list.html`  | `GET /devices`    | `devices#index`         |
| `04_device_detail.html`| `GET /devices/:id`| `devices#show`          |
| `03_borrow_return.html`| `GET /borrows`    | `borrows#index`         |
| `05_reports.html`      | `GET /reports`    | `reports#index`         |

---

## Tính năng chính

### Thiết bị (`/devices`)
- Danh sách có filter: loại, phòng, trạng thái, tìm kiếm
- CRUD đầy đủ (thêm, sửa, xóa)
- Chi tiết: thông số kỹ thuật, lịch sử mượn theo timeline, cảnh báo bảo hành

### Mượn – Trả (`/borrows`)
- Tạo phiếu mượn (chỉ chọn thiết bị `active`)
- Xác nhận trả → tự cập nhật `device.status` về `active`
- Tab filter: Tất cả / Đang mượn / Đã trả / Quá hạn
- Highlight hàng quá hạn, hiển thị số ngày trễ
- Nút "Nhắc nhở" cho phiếu quá hạn

### Báo cáo (`/reports`)
- KPI: tổng lượt mượn, % trả đúng hạn, thiết bị hỏng
- Biểu đồ cột: lượt mượn 7 tháng gần nhất
- Bar chart tỷ lệ hoạt động theo loại thiết bị
- Top 5 người mượn nhiều nhất
- Danh sách thiết bị cần xử lý

---

## Thêm tính năng (gợi ý mở rộng)

```bash
# Pagination
bundle add kaminari

# PDF export
bundle add prawn

# Authentication
bundle add devise

# Excel export  
bundle add caxlsx-rails
```
=======
# qlpm
>>>>>>> 4437741378f27b9cb8e28d04048bb3d18757065b
