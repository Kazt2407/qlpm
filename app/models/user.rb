class User < ApplicationRecord
  require "digest"

  ROLES = %w[admin approver user].freeze
  USER_TYPES = %w[admin teacher student].freeze
  ROLE_LABELS = {
    "admin" => "Quản trị",
    "approver" => "Người duyệt",
    "user" => "Người dùng"
  }.freeze
  USER_TYPE_LABELS = {
    "admin" => "Quản trị",
    "teacher" => "Giáo viên",
    "student" => "Sinh viên"
  }.freeze

  has_secure_password validations: false

  has_many :created_borrows, class_name: "Borrow", foreign_key: :created_by_id, dependent: :nullify
  has_many :approved_borrows, class_name: "Borrow", foreign_key: :approved_by_id, dependent: :nullify
  has_many :veyon_actions, dependent: :restrict_with_exception
  has_many :reported_work_orders, class_name: "WorkOrder", foreign_key: :reported_by_id, dependent: :nullify
  has_many :assigned_work_orders, class_name: "WorkOrder", foreign_key: :assigned_to_id, dependent: :nullify

  validates :full_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }
  validates :user_type, inclusion: { in: USER_TYPES }
  validates :password, presence: true, on: :create, if: -> { password_digest.blank? }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password, confirmation: true, allow_nil: true

  before_validation :normalize_email

  scope :active, -> { where(active: true) }

  def authenticate(raw_password)
    return false if raw_password.blank? || password_digest.blank?

    if bcrypt_digest?
      super(raw_password)
    else
      authenticate_legacy_password(raw_password)
    end
  end

  def admin?
    role == "admin"
  end

  def approver?
    role == "approver"
  end

  def can_review_borrows?
    admin? || approver?
  end

  def can_manage_system?
    admin?
  end

  def requester?
    role == "user" && user_type.in?(%w[teacher student])
  end

  def role_label
    ROLE_LABELS[role] || role
  end

  def user_type_label
    USER_TYPE_LABELS[user_type] || user_type
  end

  def self.role_options
    ROLES.map { |value| [ROLE_LABELS[value] || value, value] }
  end

  def self.user_type_options
    USER_TYPES.map { |value| [USER_TYPE_LABELS[value] || value, value] }
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def bcrypt_digest?
    password_digest.to_s.start_with?("$2a$", "$2b$", "$2y$")
  end

  def authenticate_legacy_password(raw_password)
    legacy_digest = Digest::SHA256.hexdigest(raw_password.to_s)
    return false unless ActiveSupport::SecurityUtils.secure_compare(password_digest, legacy_digest)

    self.password = raw_password
    save!(validate: false)
    self
  end
end
