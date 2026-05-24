class Room < ApplicationRecord
  ROOM_TYPES = %w[computer_room lab office storage other].freeze
  STATUSES = %w[active maintenance inactive].freeze
  ROOM_TYPE_LABELS = {
    "computer_room" => "Phòng máy",
    "lab" => "Phòng thí nghiệm",
    "office" => "Văn phòng",
    "storage" => "Kho",
    "other" => "Khác"
  }.freeze
  STATUS_LABELS = {
    "active" => "Đang hoạt động",
    "maintenance" => "Bảo trì",
    "inactive" => "Ngưng hoạt động"
  }.freeze

  has_many :assets, dependent: :restrict_with_exception

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :room_type, inclusion: { in: ROOM_TYPES }
  validates :status, inclusion: { in: STATUSES }

  def room_type_label
    ROOM_TYPE_LABELS[room_type] || room_type
  end

  def status_label
    STATUS_LABELS[status] || status
  end

  def self.room_type_options
    ROOM_TYPES.map { |value| [ROOM_TYPE_LABELS[value] || value, value] }
  end

  def self.status_options
    STATUSES.map { |value| [STATUS_LABELS[value] || value, value] }
  end
end
