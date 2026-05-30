class Borrow < ApplicationRecord
  belongs_to :asset
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :approved_by, class_name: "User", optional: true
  has_many :veyon_actions, dependent: :nullify

  SOURCES = %w[manual_request imported_schedule].freeze
  BORROWER_TYPES = %w[system teacher student].freeze
  WORKFLOW_STATES = %w[pending approved rejected active returned cancelled overdue].freeze
  SOURCE_LABELS = {
    "manual_request" => "Yêu cầu thủ công",
    "imported_schedule" => "Lịch nhập từ tệp"
  }.freeze
  BORROWER_TYPE_LABELS = {
    "system" => "Hệ thống",
    "teacher" => "Giáo viên",
    "student" => "Sinh viên"
  }.freeze
  WORKFLOW_STATE_LABELS = {
    "pending" => "Chờ duyệt",
    "approved" => "Đã duyệt",
    "rejected" => "Từ chối",
    "active" => "Đang mượn",
    "returned" => "Đã trả",
    "cancelled" => "Đã hủy",
    "overdue" => "Quá hạn"
  }.freeze

  validates :borrower_name, presence: true
  validates :borrow_source, inclusion: { in: SOURCES }
  validates :borrower_type, inclusion: { in: BORROWER_TYPES }
  validates :workflow_state, inclusion: { in: WORKFLOW_STATES }
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate  :ends_at_after_starts_at
  validate  :asset_must_be_borrowable
  validate  :asset_available_for_time_window

  scope :active,   -> { currently_active }
  scope :returned, -> { where.not(returned_at: nil) }
  scope :overdue,  -> { where(returned_at: nil, workflow_state: %w[approved active]).where("ends_at < ?", Time.current) }
  scope :scheduled, -> { where(returned_at: nil, workflow_state: %w[approved active]).where("starts_at > ?", Time.current) }
  scope :recent,   -> { order(starts_at: :desc) }
  scope :this_month, -> { where(starts_at: Time.current.beginning_of_month..) }
  scope :with_source, ->(source) { source.present? ? where(borrow_source: source) : all }
  scope :with_state, ->(state) { state.present? ? where(workflow_state: state) : all }
  scope :for_asset, ->(asset_id) { asset_id.present? ? where(asset_id: asset_id) : all }
  scope :borrower_like, ->(query) {
    if query.present?
      where("borrower_name LIKE :q OR borrower_identifier LIKE :q OR borrower_group LIKE :q", q: "%#{query}%")
    else
      all
    end
  }
  scope :starting_from, ->(from) { from.present? ? where("starts_at >= ?", from) : all }
  scope :ending_before, ->(to) { to.present? ? where("ends_at <= ?", to) : all }
  scope :currently_active, -> {
    where(returned_at: nil, workflow_state: %w[approved active])
      .where("starts_at <= ? AND ends_at >= ?", Time.current, Time.current)
  }

  def status
    return "cancelled" if workflow_state == "cancelled"
    return "rejected" if workflow_state == "rejected"
    return "pending" if workflow_state == "pending"
    return "returned" if returned_at.present?
    return "overdue" if ends_at < Time.current
    return "scheduled" if starts_at > Time.current
    "active"
  end

  def status_label
    {
      "pending" => "Chờ duyệt",
      "scheduled" => "Đã lên lịch",
      "active" => "Đang mượn",
      "returned" => "Đã trả",
      "overdue" => "Quá hạn",
      "cancelled" => "Đã hủy",
      "rejected" => "Từ chối"
    }[status]
  end

  def borrow_source_label
    SOURCE_LABELS[borrow_source] || borrow_source
  end

  def borrower_type_label
    BORROWER_TYPE_LABELS[borrower_type] || borrower_type
  end

  def workflow_state_label
    WORKFLOW_STATE_LABELS[workflow_state] || workflow_state
  end

  def status_color
    {
      "pending" => "sky",
      "scheduled" => "indigo",
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
    BorrowLifecycleService.mark_returned!(self)
  end

  def actionable_by_admin?
    !workflow_state.in?(%w[returned rejected cancelled])
  end

  def can_approve?
    workflow_state == "pending"
  end

  def can_reject?
    workflow_state.in?(%w[pending approved active])
  end

  def can_cancel?
    workflow_state.in?(%w[pending approved active])
  end

  def can_return?
    returned_at.blank? && workflow_state.in?(%w[approved active overdue])
  end

  def self.source_label_for(value)
    SOURCE_LABELS[value] || value
  end

  def self.borrower_type_label_for(value)
    BORROWER_TYPE_LABELS[value] || value
  end

  def self.workflow_state_label_for(value)
    WORKFLOW_STATE_LABELS[value] || value
  end

  def self.source_options
    SOURCES.map { |value| [source_label_for(value), value] }
  end

  def self.borrower_type_options
    BORROWER_TYPES.map { |value| [borrower_type_label_for(value), value] }
  end

  def self.workflow_state_options
    WORKFLOW_STATES.map { |value| [workflow_state_label_for(value), value] }
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

  def asset_must_be_borrowable
    return if asset.blank?
    return if returned_at.present? || workflow_state.in?(%w[returned rejected cancelled])
    return if asset.status.in?(%w[active borrowed in_use])

    errors.add(:asset_id, "không sẵn sàng để mượn")
  end
end
