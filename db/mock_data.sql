-- QLPM mock dataset for MySQL
-- Usage: import this file after schema/tables already exist.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE veyon_actions;
TRUNCATE TABLE borrows;
TRUNCATE TABLE veyon_hosts;
TRUNCATE TABLE assets;
TRUNCATE TABLE rooms;
TRUNCATE TABLE users;

SET FOREIGN_KEY_CHECKS = 1;

-- SHA256("password123"), app will auto-upgrade to bcrypt after first successful login.
SET @default_password_digest = 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f';

INSERT INTO users (
  id, full_name, email, role, user_type, password_digest, identifier, department, active, created_at, updated_at
) VALUES
  (1, 'Quản trị hệ thống', 'admin@school.edu.vn', 'admin', 'admin', @default_password_digest, 'ADM-001', 'CNTT', 1, NOW(), NOW()),
  (2, 'Phan Minh Duy', 'duy.approver@school.edu.vn', 'approver', 'teacher', @default_password_digest, 'DUYET-001', 'Phòng thiết bị', 1, NOW(), NOW()),
  (3, 'Trần Thị Bình', 'binh.teacher@school.edu.vn', 'user', 'teacher', @default_password_digest, 'GV-TIN-001', 'Tổ Tin học', 1, NOW(), NOW()),
  (4, 'Nguyễn Văn An', 'an.student@school.edu.vn', 'user', 'student', @default_password_digest, '10A1-001', 'Lớp 10A1', 1, NOW(), NOW()),
  (5, 'Lê Thu Lan', 'lan.teacher@school.edu.vn', 'user', 'teacher', @default_password_digest, 'GV-LY-003', 'Tổ Vật lý', 1, NOW(), NOW()),
  (6, 'Lê Minh Châu', 'chau.student@school.edu.vn', 'user', 'student', @default_password_digest, '11B2-014', 'Lớp 11B2', 1, NOW(), NOW());

INSERT INTO rooms (
  id, code, name, room_type, status, capacity, location, notes, created_at, updated_at
) VALUES
  (1, 'LAB-A', 'Phòng A', 'computer_room', 'active', 40, 'Tầng 2 dãy A', NULL, NOW(), NOW()),
  (2, 'LAB-B', 'Phòng B', 'computer_room', 'active', 35, 'Tầng 2 dãy B', NULL, NOW(), NOW()),
  (3, 'LAB-C', 'Phòng C', 'computer_room', 'maintenance', 30, 'Tầng 3 dãy A', 'Đang bảo trì điện', NOW(), NOW());

INSERT INTO assets (
  id, code, name, asset_type, category, room_id, parent_id, status, brand, model_code, serial_number,
  imported_at, warranty_until, desk_number, cpu, ram, storage, os, ip_address, notes, created_at, updated_at
) VALUES
  (1, 'ASSET-LAB-A', 'Phòng máy A', 'room', 'computer_room', 1, NULL, 'active', NULL, NULL, NULL, '2024-01-12', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()),
  (2, 'ASSET-LAB-B', 'Phòng máy B', 'room', 'computer_room', 2, NULL, 'active', NULL, NULL, NULL, '2024-01-12', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()),
  (3, 'PC-A-001', 'Máy tính Dell A01', 'computer', 'computer', 1, 1, 'active', 'Dell', 'OptiPlex 3080', 'DL-A01-2024', '2024-01-12', '2027-01-12', 1, 'Intel Core i5-10400', '8 GB', '256 GB SSD', 'Windows 10 Pro', '192.168.1.101', NULL, NOW(), NOW()),
  (4, 'PC-A-002', 'Máy tính Dell A02', 'computer', 'computer', 1, 1, 'borrowed', 'Dell', 'OptiPlex 3080', 'DL-A02-2024', '2024-01-12', '2027-01-12', 2, 'Intel Core i5-10400', '8 GB', '256 GB SSD', 'Windows 10 Pro', '192.168.1.102', NULL, NOW(), NOW()),
  (5, 'PC-B-001', 'Máy tính HP B01', 'computer', 'computer', 2, 2, 'in_use', 'HP', 'ProDesk 400 G7', 'HP-B01-2023', '2023-06-05', '2026-06-05', 1, 'Intel Core i5-10500', '8 GB', '512 GB SSD', 'Windows 11 Pro', '192.168.2.101', NULL, NOW(), NOW()),
  (6, 'MS-B-005', 'Chuột Logitech M100', 'device', 'mouse', 2, NULL, 'active', 'Logitech', 'M100', 'LOGI-M100-05', '2023-06-05', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()),
  (7, 'KB-C-008', 'Bàn phím VSP KB-150', 'device', 'keyboard', 3, NULL, 'borrowed', 'VSP', 'KB-150', 'VSP-KB-08', '2023-09-18', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()),
  (8, 'MN-A-007', 'Màn hình LG 22', 'device', 'monitor', 1, NULL, 'active', 'LG', '22MK400H', 'LG-MN-07', '2024-01-12', '2026-01-12', 7, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()),
  (9, 'PJ-A-001', 'Máy chiếu Epson A1', 'device', 'projector', 1, NULL, 'maintenance', 'Epson', 'EB-X06', 'EPS-PJ-001', '2022-08-10', '2025-08-10', NULL, NULL, NULL, NULL, NULL, NULL, 'Đang bảo dưỡng bóng đèn', NOW(), NOW());

INSERT INTO borrows (
  id, asset_id, created_by_id, approved_by_id, borrow_source, borrower_type, borrower_name,
  borrower_identifier, borrower_group, starts_at, ends_at, returned_at, workflow_state,
  purpose, notes, import_batch, import_row_number, created_at, updated_at, approved_at, reminded_at, reminder_channel
) VALUES
  (1, 4, 4, NULL, 'manual_request', 'student', 'Nguyễn Văn An', '10A1-001', 'Lớp 10A1',
   '2026-05-12 13:00:00', '2026-05-12 15:00:00', NULL, 'pending',
   'Làm bài thực hành', NULL, NULL, NULL, NOW(), NOW(), NULL, NULL, NULL),

  (2, 6, 3, 2, 'manual_request', 'teacher', 'Trần Thị Bình', 'GV-TIN-001', 'Tổ Tin học',
   '2026-05-12 08:00:00', '2026-05-12 10:30:00', NULL, 'approved',
   'Chuẩn bị giờ dạy', NULL, NULL, NULL, NOW(), NOW(), NOW(), NULL, NULL),

  (3, 5, 5, 2, 'manual_request', 'teacher', 'Lê Thu Lan', 'GV-LY-003', 'Tổ Vật lý',
   '2026-05-11 09:00:00', '2026-05-11 16:00:00', NULL, 'active',
   'Thực nghiệm mô phỏng', NULL, NULL, NULL, NOW(), NOW(), NOW(), NULL, NULL),

  (4, 6, 3, 2, 'manual_request', 'teacher', 'Trần Thị Bình', 'GV-TIN-001', 'Tổ Tin học',
   '2026-05-09 08:00:00', '2026-05-09 11:30:00', '2026-05-09 11:20:00', 'returned',
   'Mượn tạm phục vụ bài dạy', NULL, NULL, NULL, NOW(), NOW(), NOW(), NULL, NULL),

  (5, 7, 6, 2, 'manual_request', 'student', 'Lê Minh Châu', '11B2-014', 'Lớp 11B2',
   '2026-05-07 09:00:00', '2026-05-08 16:00:00', NULL, 'active',
   'Ôn tập phòng thi', NULL, NULL, NULL, NOW(), NOW(), NOW(), '2026-05-09 08:00:00', 'email'),

  (6, 8, 4, 2, 'manual_request', 'student', 'Nguyễn Văn An', '10A1-001', 'Lớp 10A1',
   '2026-05-13 13:00:00', '2026-05-13 16:00:00', NULL, 'rejected',
   'Trình chiếu bài tập', 'Không đủ điều kiện mượn trong ca này', NULL, NULL, NOW(), NOW(), NULL, NULL, NULL),

  (7, 9, 4, 2, 'manual_request', 'student', 'Nguyễn Văn An', '10A1-001', 'Lớp 10A1',
   '2026-05-14 13:00:00', '2026-05-14 15:00:00', NULL, 'cancelled',
   'Thuyết trình nhóm', 'Người mượn hủy yêu cầu', NULL, NULL, NOW(), NOW(), NOW(), NULL, NULL),

  (8, 1, NULL, 2, 'imported_schedule', 'system', 'Hệ thống xếp lịch', 'SHEET-2026-W20', 'Lớp 12C3',
   '2026-05-13 07:00:00', '2026-05-13 09:30:00', NULL, 'approved',
   'Tiết thực hành theo lịch', NULL, 'schedule_2026_week_20.xlsx', 12, NOW(), NOW(), NOW(), NULL, NULL);

INSERT INTO veyon_hosts (
  id, asset_id, host, service_port, enabled, last_seen_at, metadata_json, created_at, updated_at
) VALUES
  (1, 3, 'pc-a-001.school.local', 11100, 1, NOW(), JSON_OBJECT('room', 'LAB-A', 'note', 'Máy đầu dãy A'), NOW(), NOW()),
  (2, 5, 'pc-b-001.school.local', 11100, 1, NOW(), JSON_OBJECT('room', 'LAB-B', 'note', 'Máy demo điều khiển'), NOW(), NOW());

INSERT INTO veyon_actions (
  id, user_id, borrow_id, asset_id, veyon_host_id, host, feature_key, status,
  error_code, error_message, request_payload_json, response_payload_json, created_at, updated_at
) VALUES
  (1, 2, 2, 6, 2, 'pc-b-001.school.local:11100', 'text_message', 'success',
   NULL, NULL, JSON_OBJECT('active', true, 'arguments', JSON_OBJECT('text', 'Xin bắt đầu tiết học')),
   JSON_OBJECT('success', true), NOW(), NOW()),
  (2, 2, 5, 7, 1, 'pc-a-001.school.local:11100', 'screen_lock', 'failed',
   'gateway_unreachable', 'Không kết nối được gateway', JSON_OBJECT('active', true),
   JSON_OBJECT('success', false), NOW(), NOW());

-- Keep AUTO_INCREMENT in sync with manual ids
ALTER TABLE users AUTO_INCREMENT = 100;
ALTER TABLE rooms AUTO_INCREMENT = 100;
ALTER TABLE assets AUTO_INCREMENT = 1000;
ALTER TABLE borrows AUTO_INCREMENT = 1000;
ALTER TABLE veyon_hosts AUTO_INCREMENT = 1000;
ALTER TABLE veyon_actions AUTO_INCREMENT = 1000;
