class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  enum :role, {
    employee: "employee",
    admin: "admin",
    super_admin: "super_admin"
  }, prefix: true

  validates :role, presence: true
  validate :single_super_admin, if: :role_super_admin?

  before_validation :set_default_role, on: :create

  scope :managed_by_admin, -> { where(role: "employee") }

  def can_manage_users?
    role_super_admin? || role_admin?
  end

  def can_manage?(user)
    return false if user.blank?
    return false if user == self
    return false if user.role_super_admin?
    return manageable_roles.include?(user.role)
  end

  def manageable_roles
    return %w[admin employee] if role_super_admin?
    return %w[employee] if role_admin?

    []
  end

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :inactive
  end

  private

  def set_default_role
    self.role ||= "employee"
  end

  def single_super_admin
    scope = self.class.where(role: "super_admin")
    scope = scope.where.not(id: id) if persisted?
    errors.add(:role, "can only have one super admin") if scope.exists?
  end
end
