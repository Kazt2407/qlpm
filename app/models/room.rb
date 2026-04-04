class Room < ApplicationRecord
  ROOM_TYPES = %w[computer_room lab office storage other].freeze
  STATUSES = %w[active maintenance inactive].freeze

  has_many :assets, dependent: :restrict_with_exception

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :room_type, inclusion: { in: ROOM_TYPES }
  validates :status, inclusion: { in: STATUSES }
end
