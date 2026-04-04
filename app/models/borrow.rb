class Borrow < ApplicationRecord
  belongs_to :asset
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true

  SOURCES = %w[manual_request imported_schedule].freeze
  BORROWER_TYPES = %w[system teacher student].freeze
  WORKFLOW_STATES = %w[pending approved rejected active returned cancelled overdue].freeze

  validates :borrower_name, presence: true
  validates :borrow_source, inclusion: { in: SOURCES }
  validates :borrower_type, inclusion: { in: BORROWER_TYPES }
  validates :workflow_state, inclusion: { in: WORKFLOW_STATES }
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate  :ends_at_after_starts_at
  validate  :asset_available_for_time_window

  scope :active,   -> { where(returned_at: nil, workflow_state: %w[approved active]).where("ends_at >= ?", Time.current) }
  scope :returned, -> { where.not(returned_at: nil) }
  scope :overdue,  -> { where(returned_at: nil, workflow_state: %w[approved active]).where("ends_at < ?", Time.current) }
  scope :recent,   -> { order(starts_at: :desc) }
  scope :this_month, -> { where(starts_at: Time.current.beginning_of_month..) }

  def status
    return "cancelled" if workflow_state == "cancelled"
    return "rejected" if workflow_state == "rejected"
    return "pending" if workflow_state == "pending"
    return "returned" if returned_at.present?
    return "overdue" if ends_at < Time.current
    "active"
  end

  def status_label
    {
      "pending" => "Chờ duyệt",
      "active" => "Đang mượn",
      "returned" => "Đã trả",
      "overdue" => "Quá hạn",
      "cancelled" => "Đã hủy",
      "rejected" => "Từ chối"
    }[status]
  end

  def status_color
    {
      "pending" => "sky",
      "active" => "amber",
      "returned" => "emerald",
      "overdue" => "red",
      "cancelled" => "gray",
      "rejected" => "rose"
    }[status]
  end

  def days_overdue
    return 0 unless overdue?
    ((Time.current - ends_at) / 1.day).ceil
  end

  def overdue?
    returned_at.nil? && ends_at < Time.current
  end

  def confirm_return!
    transaction do
      update!(returned_at: Time.current, workflow_state: "returned")
      asset.update!(status: "active") if asset.status.in?(%w[borrowed in_use])
    end
  end

  private

  def ends_at_after_starts_at
    return unless starts_at && ends_at
    errors.add(:ends_at, "phải sau thời gian bắt đầu") if ends_at <= starts_at
  end

  def asset_available_for_time_window
    return if returned_at.present? || asset.blank? || starts_at.blank? || ends_at.blank?

    overlapping = asset.borrows
                       .where.not(id: id)
                       .where(returned_at: nil)
                       .where.not(workflow_state: %w[cancelled rejected returned])
                       .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
    return unless overlapping.exists?

    errors.add(:asset_id, "đã có lịch sử dụng trùng thời gian")
  end
end
