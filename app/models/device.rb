class Device < ApplicationRecord
  has_many :borrows, dependent: :destroy

  TYPES = %w[Máy\ tính Màn\ hình Bàn\ phím Chuột Dây\ mạng].freeze
  ROOMS = %w[Phòng\ A Phòng\ B Phòng\ C].freeze
  STATUSES = %w[active borrowed broken maintenance].freeze

  validates :code,        presence: true, uniqueness: true
  validates :name,        presence: true
  validates :device_type, presence: true, inclusion: { in: TYPES }
  validates :room,        presence: true, inclusion: { in: ROOMS }
  validates :status,      inclusion: { in: STATUSES }
  validates :imported_at, presence: true

  scope :active,      -> { where(status: "active") }
  scope :borrowed,    -> { where(status: "borrowed") }
  scope :broken,      -> { where(status: "broken") }
  scope :maintenance, -> { where(status: "maintenance") }
  scope :by_room,     ->(room) { where(room: room) if room.present? }
  scope :by_type,     ->(t)    { where(device_type: t) if t.present? }
  scope :search,      ->(q)    { where("name LIKE ? OR code LIKE ?", "%#{q}%", "%#{q}%") if q.present? }

  def status_label
    { "active" => "Hoạt động", "borrowed" => "Đang mượn",
      "broken" => "Hỏng",     "maintenance" => "Bảo trì" }[status]
  end

  def status_color
    { "active"      => "emerald",
      "borrowed"    => "amber",
      "broken"      => "red",
      "maintenance" => "gray" }[status]
  end

  def currently_borrowed?
    borrows.where(returned_at: nil).exists?
  end

  def active_borrow
    borrows.where(returned_at: nil).order(borrowed_at: :desc).first
  end

  def borrow_count
    borrows.count
  end
end
