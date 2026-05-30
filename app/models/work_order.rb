class WorkOrder < ApplicationRecord
  PRIORITIES = %w[low normal high urgent].freeze
  STATUSES = %w[open in_progress resolved cancelled].freeze
  PRIORITY_LABELS = {
    "low" => "Thấp",
    "normal" => "Bình thường",
    "high" => "Cao",
    "urgent" => "Khẩn cấp"
  }.freeze
  STATUS_LABELS = {
    "open" => "Mới",
    "in_progress" => "Đang xử lý",
    "resolved" => "Đã xử lý",
    "cancelled" => "Đã hủy"
  }.freeze

  belongs_to :asset
  belongs_to :reported_by, class_name: "User", optional: true
  belongs_to :assigned_to, class_name: "User", optional: true

  validates :title, presence: true
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }
  validates :cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :open, -> { where(status: %w[open in_progress]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_status, ->(value) { value.present? ? where(status: value) : all }
  scope :with_priority, ->(value) { value.present? ? where(priority: value) : all }
  scope :for_asset, ->(asset_id) { asset_id.present? ? where(asset_id: asset_id) : all }

  before_validation :set_resolved_at

  def status_label
    STATUS_LABELS[status] || status
  end

  def priority_label
    PRIORITY_LABELS[priority] || priority
  end

  def status_color
    {
      "open" => "amber",
      "in_progress" => "sky",
      "resolved" => "emerald",
      "cancelled" => "gray"
    }[status]
  end

  def priority_color
    {
      "low" => "slate",
      "normal" => "sky",
      "high" => "amber",
      "urgent" => "red"
    }[priority]
  end

  def self.priority_options
    PRIORITIES.map { |value| [PRIORITY_LABELS[value], value] }
  end

  def self.status_options
    STATUSES.map { |value| [STATUS_LABELS[value], value] }
  end

  private

  def set_resolved_at
    self.resolved_at ||= Time.current if status == "resolved"
    self.resolved_at = nil if status != "resolved"
  end
end
