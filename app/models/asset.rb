class Asset < ApplicationRecord
  ASSET_TYPES = %w[room computer device].freeze
  CATEGORIES = %w[
    computer_room
    computer
    monitor
    keyboard
    mouse
    network_cable
    projector
    printer
    other
  ].freeze
  STATUSES = %w[active borrowed in_use broken maintenance inactive].freeze
  ASSET_TYPE_LABELS = {
    "room" => "Phòng máy",
    "computer" => "Máy tính",
    "device" => "Thiết bị"
  }.freeze
  CATEGORY_LABELS = {
    "computer_room" => "Phòng máy",
    "computer" => "Máy tính",
    "monitor" => "Màn hình",
    "keyboard" => "Bàn phím",
    "mouse" => "Chuột",
    "network_cable" => "Cáp mạng",
    "projector" => "Máy chiếu",
    "printer" => "Máy in",
    "other" => "Khác"
  }.freeze
  STATUS_LABELS = {
    "active" => "Sẵn sàng",
    "borrowed" => "Đang mượn",
    "in_use" => "Đang sử dụng",
    "broken" => "Hỏng",
    "maintenance" => "Bảo trì",
    "inactive" => "Ngưng dùng"
  }.freeze

  belongs_to :room, optional: true
  belongs_to :parent, class_name: "Asset", optional: true

  has_many :children, class_name: "Asset", foreign_key: :parent_id, dependent: :nullify
  has_many :borrows, dependent: :restrict_with_exception
  has_many :work_orders, dependent: :restrict_with_exception
  has_one :veyon_host, dependent: :destroy
  has_many :veyon_actions, dependent: :restrict_with_exception

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :asset_type, inclusion: { in: ASSET_TYPES }
  validates :category, inclusion: { in: CATEGORIES }
  validates :status, inclusion: { in: STATUSES }

  delegate :name, to: :room, prefix: true, allow_nil: true

  scope :rooms, -> { where(asset_type: "room") }
  scope :computers, -> { where(asset_type: "computer") }
  scope :devices, -> { where(asset_type: "device") }
  scope :active, -> { where(status: "active") }
  scope :search, ->(q) {
    where("code LIKE :q OR name LIKE :q OR serial_number LIKE :q", q: "%#{q}%") if q.present?
  }

  def status_label
    STATUS_LABELS[status]
  end

  def status_color
    {
      "active" => "emerald",
      "borrowed" => "amber",
      "in_use" => "sky",
      "broken" => "red",
      "maintenance" => "gray",
      "inactive" => "slate"
    }[status]
  end

  def asset_type_label
    ASSET_TYPE_LABELS[asset_type]
  end

  def category_label
    CATEGORY_LABELS[category] || category
  end

  def self.asset_type_label_for(value)
    ASSET_TYPE_LABELS[value] || value
  end

  def self.category_label_for(value)
    CATEGORY_LABELS[value] || value
  end

  def self.status_label_for(value)
    STATUS_LABELS[value] || value
  end

  def self.asset_type_options
    ASSET_TYPES.map { |value| [asset_type_label_for(value), value] }
  end

  def self.category_options
    CATEGORIES.map { |value| [category_label_for(value), value] }
  end

  def self.status_options
    STATUSES.map { |value| [status_label_for(value), value] }
  end
end
