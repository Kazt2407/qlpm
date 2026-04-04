class User < ApplicationRecord
  require "digest"

  ROLES = %w[admin user].freeze
  USER_TYPES = %w[admin teacher student].freeze

  has_many :created_borrows, class_name: "Borrow", foreign_key: :created_by_id, dependent: :nullify
  has_many :approved_borrows, class_name: "Borrow", foreign_key: :approved_by_id, dependent: :nullify

  validates :full_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }
  validates :user_type, inclusion: { in: USER_TYPES }

  def password=(raw_password)
    self.password_digest = Digest::SHA256.hexdigest(raw_password.to_s)
  end

  def authenticate(raw_password)
    return false if password_digest.blank?

    password_digest == Digest::SHA256.hexdigest(raw_password.to_s)
  end

  def admin?
    role == "admin"
  end
end
