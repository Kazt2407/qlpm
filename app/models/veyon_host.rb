class VeyonHost < ApplicationRecord
  belongs_to :asset
  has_many :veyon_actions, dependent: :nullify

  validates :host, presence: true
  validates :host, uniqueness: { scope: :service_port }
  validates :asset_id, uniqueness: true
  validates :service_port, numericality: { greater_than: 0, less_than_or_equal_to: 65_535 }

  scope :enabled, -> { where(enabled: true) }
  scope :recent, -> { order(updated_at: :desc) }

  def target_endpoint
    "#{host}:#{service_port}"
  end

  def health_state
    return "online" if last_seen_at.present? && last_seen_at >= 5.minutes.ago

    "offline"
  end
end
