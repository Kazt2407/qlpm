class VeyonAction < ApplicationRecord
  STATUSES = %w[queued sent success failed].freeze
  FEATURE_KEYS = %w[
    screen_lock
    input_devices_lock
    user_logoff
    reboot
    power_down
    text_message
    open_website
    start_app
  ].freeze

  belongs_to :user
  belongs_to :borrow, optional: true
  belongs_to :asset
  belongs_to :veyon_host, optional: true

  validates :host, presence: true
  validates :feature_key, inclusion: { in: FEATURE_KEYS }
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc) }
  scope :with_status, ->(value) { value.present? ? where(status: value) : all }

  def success?
    status == "success"
  end
end
