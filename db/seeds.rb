# db/seeds.rb – Sample data for PhòngMáy Pro
puts "Seeding database..."

Device.destroy_all
Borrow.destroy_all

# ── Devices ──────────────────────────────────────────────────
devices_data = [
  # Phòng A – Máy tính
  { code: "PC-A-001", name: "Máy tính Dell OptiPlex", device_type: "Máy tính", room: "Phòng A", brand: "Dell", device_name: "OptiPlex 3080", desk_number: 1, imported_at: "2024-01-12", warranty_until: "2027-01-12", status: "active", cpu: "Intel Core i5-10400", ram: "8 GB DDR4", storage: "256 GB SSD", os: "Windows 10 Pro", ip_address: "192.168.1.101" },
  { code: "PC-A-002", name: "Máy tính Dell OptiPlex", device_type: "Máy tính", room: "Phòng A", brand: "Dell", device_name: "OptiPlex 3080", desk_number: 2, imported_at: "2024-01-12", warranty_until: "2027-01-12", status: "borrowed", cpu: "Intel Core i5-10400", ram: "8 GB DDR4", storage: "256 GB SSD", os: "Windows 10 Pro", ip_address: "192.168.1.102" },
  { code: "PC-A-003", name: "Máy tính Dell OptiPlex", device_type: "Máy tính", room: "Phòng A", brand: "Dell", device_name: "OptiPlex 3080", desk_number: 3, imported_at: "2024-01-12", warranty_until: "2027-01-12", status: "active", ip_address: "192.168.1.103" },
  # Phòng B
  { code: "PC-B-001", name: "Máy tính HP ProDesk", device_type: "Máy tính", room: "Phòng B", brand: "HP", device_name: "ProDesk 400 G7", desk_number: 1, imported_at: "2023-06-05", warranty_until: "2026-06-05", status: "active", ip_address: "192.168.2.101" },
  { code: "PC-B-002", name: "Máy tính HP ProDesk", device_type: "Máy tính", room: "Phòng B", brand: "HP", device_name: "ProDesk 400 G7", desk_number: 2, imported_at: "2023-06-05", warranty_until: "2026-06-05", status: "maintenance", notes: "Lỗi ổ cứng, đang chờ thay thế" },
  # Chuột
  { code: "MS-B-005", name: "Chuột Logitech M100", device_type: "Chuột", room: "Phòng B", brand: "Logitech", device_name: "M100", imported_at: "2023-06-05", status: "active" },
  { code: "MS-B-007", name: "Chuột Logitech M100", device_type: "Chuột", room: "Phòng B", brand: "Logitech", device_name: "M100", imported_at: "2023-06-05", status: "broken", notes: "Cuộn chuột bị hỏng" },
  # Bàn phím
  { code: "KB-C-003", name: "Bàn phím VSP KB-150", device_type: "Bàn phím", room: "Phòng C", brand: "VSP", device_name: "KB-150", imported_at: "2023-09-18", status: "active" },
  { code: "KB-C-008", name: "Bàn phím VSP KB-150", device_type: "Bàn phím", room: "Phòng C", brand: "VSP", device_name: "KB-150", imported_at: "2023-09-18", status: "active" },
  # Màn hình
  { code: "MN-A-004", name: 'Màn hình LG 22" FHD', device_type: "Màn hình", room: "Phòng A", brand: "LG", device_name: '22MK400H', desk_number: 4, imported_at: "2024-01-12", warranty_until: "2026-01-12", status: "maintenance" },
  { code: "MN-A-007", name: 'Màn hình LG 22" FHD', device_type: "Màn hình", room: "Phòng A", brand: "LG", device_name: '22MK400H', desk_number: 7, imported_at: "2024-01-12", warranty_until: "2026-01-12", status: "active" },
  # Dây mạng
  { code: "NET-A-001", name: "Dây mạng CAT6", device_type: "Dây mạng", room: "Phòng A", brand: "AMP", imported_at: "2024-01-12", status: "active" },
]

devices = devices_data.map { |d| Device.create!(d) }
puts "  Created #{Device.count} devices"

# ── Borrows ───────────────────────────────────────────────────
pc_a_002 = Device.find_by(code: "PC-A-002")
ms_b_005 = Device.find_by(code: "MS-B-005")
kb_c_008 = Device.find_by(code: "KB-C-008")
mn_a_007 = Device.find_by(code: "MN-A-007")

[
  # Currently borrowing
  { device: pc_a_002, borrower_name: "Nguyễn Văn An", borrower_class: "Lớp 10A1", borrowed_at: 1.day.ago, due_at: Date.tomorrow, purpose: "Học bù buổi chiều lớp 10A1" },
  # Returned
  { device: ms_b_005, borrower_name: "Trần Thị Bình", borrower_class: "Giáo viên Tin học", borrowed_at: 2.days.ago, due_at: 1.day.ago, returned_at: 1.day.ago.change(hour: 13, min: 15), purpose: "Chuẩn bị bài giảng" },
  { device: mn_a_007, borrower_name: "Phạm Quốc Duy", borrower_class: "Lớp 12C3", borrowed_at: 3.days.ago, due_at: 2.days.ago, returned_at: 2.days.ago.change(hour: 16, min: 45) },
  # Overdue
  { device: kb_c_008, borrower_name: "Lê Minh Châu", borrower_class: "Lớp 11B2", borrowed_at: 5.days.ago, due_at: 4.days.ago, purpose: "Ôn thi học kỳ" },
].each { |b| Borrow.create!(b) }

puts "  Created #{Borrow.count} borrows"
puts "Done! ✓"
