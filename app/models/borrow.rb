class Borrow < ApplicationRecord
  belongs_to :device

  STATUSES = %w[borrowing returned overdue].freeze

  validates :borrower_name, presence: true
  validates :borrower_class, presence: true
  validates :borrowed_at,   presence: true
  validates :due_at,        presence: true
  validate  :due_at_after_borrowed_at
  validate  :device_available_for_open_borrow

  scope :borrowing, -> { where(returned_at: nil).where("due_at >= ?", Date.today) }
  scope :returned,  -> { where.not(returned_at: nil) }
  scope :overdue,   -> { where(returned_at: nil).where("due_at < ?", Date.today) }
  scope :recent,    -> { order(borrowed_at: :desc) }
  scope :this_month, -> { where(borrowed_at: Date.current.beginning_of_month..) }

  def status
    return "returned" if returned_at.present?
    return "overdue"  if due_at < Date.today
    "borrowing"
  end

  def status_label
    { "borrowing" => "Đang mượn", "returned" => "Đã trả", "overdue" => "Quá hạn" }[status]
  end

  def status_color
    { "borrowing" => "amber", "returned" => "emerald", "overdue" => "red" }[status]
  end

  def days_overdue
    return 0 unless overdue?
    (Date.today - due_at.to_date).to_i
  end

  def overdue?
    returned_at.nil? && due_at < Date.today
  end

  def confirm_return!
    transaction do
      update!(returned_at: Time.current)
      device.update!(status: "active")
    end
  end

  private

  def due_at_after_borrowed_at
    return unless borrowed_at && due_at
    errors.add(:due_at, "phải sau ngày mượn") if due_at < borrowed_at
  end

  def device_available_for_open_borrow
    return if returned_at.present? || device.blank?

    open_borrows = device.borrows.where(returned_at: nil).where.not(id: id)
    return unless open_borrows.exists? || !device.status.in?(%w[active borrowed])

    errors.add(:device_id, "đang có phiếu mượn chưa trả")
  end
end
