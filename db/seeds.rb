puts "Seeding rebuilt database..."

Borrow.delete_all
Asset.delete_all
Room.delete_all
User.delete_all

users = {
  admin: User.create!(
    full_name: "Quản trị hệ thống",
    email: "admin@school.edu.vn",
    role: "admin",
    user_type: "admin",
    password: "password123",
    identifier: "ADM-001",
    department: "CNTT"
  ),
  approver: User.create!(
    full_name: "Phan Minh Duy",
    email: "duy.approver@school.edu.vn",
    role: "approver",
    user_type: "teacher",
    password: "password123",
    identifier: "DUYET-001",
    department: "Phòng thiết bị"
  ),
  teacher: User.create!(
    full_name: "Trần Thị Bình",
    email: "binh.teacher@school.edu.vn",
    role: "user",
    user_type: "teacher",
    password: "password123",
    identifier: "GV-TIN-001",
    department: "Tổ Tin học"
  ),
  student: User.create!(
    full_name: "Nguyễn Văn An",
    email: "an.student@school.edu.vn",
    role: "user",
    user_type: "student",
    password: "password123",
    identifier: "10A1-001",
    department: "Lớp 10A1"
  )
}

puts "  Created #{User.count} users"

rooms = {
  a: Room.create!(
    code: "LAB-A",
    name: "Phòng A",
    room_type: "computer_room",
    status: "active",
    capacity: 40,
    location: "Tầng 2 dãy A"
  ),
  b: Room.create!(
    code: "LAB-B",
    name: "Phòng B",
    room_type: "computer_room",
    status: "active",
    capacity: 35,
    location: "Tầng 2 dãy B"
  ),
  c: Room.create!(
    code: "LAB-C",
    name: "Phòng C",
    room_type: "computer_room",
    status: "maintenance",
    capacity: 30,
    location: "Tầng 3 dãy A",
    notes: "Đang cải tạo hệ thống điện"
  )
}

puts "  Created #{Room.count} rooms"

assets = {}

assets[:room_a] = Asset.create!(
  code: "ASSET-LAB-A",
  name: "Phòng máy A",
  asset_type: "room",
  category: "computer_room",
  room: rooms[:a],
  status: "active",
  notes: "Dùng cho lịch thực hành theo thời khóa biểu"
)

assets[:room_b] = Asset.create!(
  code: "ASSET-LAB-B",
  name: "Phòng máy B",
  asset_type: "room",
  category: "computer_room",
  room: rooms[:b],
  status: "active"
)

assets[:pc_a_01] = Asset.create!(
  code: "PC-A-001",
  name: "Máy tính Dell OptiPlex A01",
  asset_type: "computer",
  category: "computer",
  room: rooms[:a],
  parent: assets[:room_a],
  status: "active",
  brand: "Dell",
  model_code: "OptiPlex 3080",
  serial_number: "DL-A01-2024",
  imported_at: Date.new(2024, 1, 12),
  warranty_until: Date.new(2027, 1, 12),
  desk_number: 1,
  cpu: "Intel Core i5-10400",
  ram: "8 GB DDR4",
  storage: "256 GB SSD",
  os: "Windows 10 Pro",
  ip_address: "192.168.1.101"
)

assets[:pc_a_02] = Asset.create!(
  code: "PC-A-002",
  name: "Máy tính Dell OptiPlex A02",
  asset_type: "computer",
  category: "computer",
  room: rooms[:a],
  parent: assets[:room_a],
  status: "borrowed",
  brand: "Dell",
  model_code: "OptiPlex 3080",
  serial_number: "DL-A02-2024",
  imported_at: Date.new(2024, 1, 12),
  warranty_until: Date.new(2027, 1, 12),
  desk_number: 2,
  cpu: "Intel Core i5-10400",
  ram: "8 GB DDR4",
  storage: "256 GB SSD",
  os: "Windows 10 Pro",
  ip_address: "192.168.1.102"
)

assets[:pc_b_01] = Asset.create!(
  code: "PC-B-001",
  name: "Máy tính HP ProDesk B01",
  asset_type: "computer",
  category: "computer",
  room: rooms[:b],
  parent: assets[:room_b],
  status: "active",
  brand: "HP",
  model_code: "ProDesk 400 G7",
  serial_number: "HP-B01-2023",
  imported_at: Date.new(2023, 6, 5),
  warranty_until: Date.new(2026, 6, 5),
  desk_number: 1,
  cpu: "Intel Core i5-10500",
  ram: "8 GB DDR4",
  storage: "512 GB SSD",
  os: "Windows 11 Pro",
  ip_address: "192.168.2.101"
)

assets[:mouse_b_05] = Asset.create!(
  code: "MS-B-005",
  name: "Chuột Logitech M100",
  asset_type: "device",
  category: "mouse",
  room: rooms[:b],
  status: "active",
  brand: "Logitech",
  model_code: "M100",
  serial_number: "LOGI-M100-05",
  imported_at: Date.new(2023, 6, 5)
)

assets[:keyboard_c_08] = Asset.create!(
  code: "KB-C-008",
  name: "Bàn phím VSP KB-150",
  asset_type: "device",
  category: "keyboard",
  room: rooms[:c],
  status: "borrowed",
  brand: "VSP",
  model_code: "KB-150",
  serial_number: "VSP-KB-08",
  imported_at: Date.new(2023, 9, 18)
)

assets[:monitor_a_07] = Asset.create!(
  code: "MN-A-007",
  name: "Màn hình LG 22 FHD",
  asset_type: "device",
  category: "monitor",
  room: rooms[:a],
  status: "active",
  brand: "LG",
  model_code: "22MK400H",
  serial_number: "LG-MN-07",
  imported_at: Date.new(2024, 1, 12),
  warranty_until: Date.new(2026, 1, 12),
  desk_number: 7
)

puts "  Created #{Asset.count} assets"

Borrow.create!(
  asset: assets[:pc_a_02],
  created_by: users[:student],
  approved_by: users[:admin],
  borrow_source: "manual_request",
  borrower_type: "student",
  borrower_name: "Nguyễn Văn An",
  borrower_identifier: "10A1-001",
  borrower_group: "Lớp 10A1",
  starts_at: 1.day.ago.change(hour: 13, min: 0),
  ends_at: Time.current.change(hour: 17, min: 0),
  workflow_state: "active",
  purpose: "Học bù buổi chiều"
)

Borrow.create!(
  asset: assets[:mouse_b_05],
  created_by: users[:teacher],
  approved_by: users[:admin],
  borrow_source: "manual_request",
  borrower_type: "teacher",
  borrower_name: "Trần Thị Bình",
  borrower_identifier: "GV-TIN-001",
  borrower_group: "Tổ Tin học",
  starts_at: 2.days.ago.change(hour: 8, min: 0),
  ends_at: 1.day.ago.change(hour: 11, min: 30),
  returned_at: 1.day.ago.change(hour: 11, min: 15),
  workflow_state: "returned",
  purpose: "Chuẩn bị bài giảng"
)

Borrow.create!(
  asset: assets[:keyboard_c_08],
  created_by: users[:student],
  approved_by: users[:admin],
  borrow_source: "manual_request",
  borrower_type: "student",
  borrower_name: "Lê Minh Châu",
  borrower_identifier: "11B2-014",
  borrower_group: "Lớp 11B2",
  starts_at: 5.days.ago.change(hour: 9, min: 0),
  ends_at: 4.days.ago.change(hour: 16, min: 0),
  workflow_state: "active",
  purpose: "Ôn thi học kỳ"
)

Borrow.create!(
  asset: assets[:room_a],
  approved_by: users[:admin],
  borrow_source: "imported_schedule",
  borrower_type: "system",
  borrower_name: "Hệ thống xếp lịch",
  borrower_identifier: "SHEET-2026-W14",
  borrower_group: "Lớp 12C3",
  starts_at: 1.day.from_now.change(hour: 7, min: 0),
  ends_at: 1.day.from_now.change(hour: 9, min: 30),
  workflow_state: "approved",
  purpose: "Tiết thực hành theo file lịch phòng máy",
  import_batch: "schedule_2026_week_14.xlsx",
  import_row_number: 12
)

puts "  Created #{Borrow.count} borrows"

if defined?(VeyonHost)
  VeyonHost.delete_all

  VeyonHost.create!(
    asset: assets[:pc_a_01],
    host: "pc-a-001.school.local",
    service_port: 11_100,
    enabled: true,
    metadata_json: { room: "LAB-A", note: "Máy đầu dãy A" }
  )

  VeyonHost.create!(
    asset: assets[:pc_b_01],
    host: "pc-b-001.school.local",
    service_port: 11_100,
    enabled: true,
    metadata_json: { room: "LAB-B", note: "Máy demo điều khiển" }
  )

  puts "  Created #{VeyonHost.count} veyon hosts"
end

puts "Done! Database rebuilt successfully."
