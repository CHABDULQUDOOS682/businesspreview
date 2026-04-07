class ApplicationController < ActionController::Base
  include Pagy::Backend
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  before_action :authenticate_user!
  before_action :set_unread_message_count, if: :user_signed_in?
  before_action :prepend_role_specific_admin_views, if: :role_specific_admin_views?
  helper_method :unread_message_count, :current_role_label, :can_manage_users?,
                :super_admin?, :admin_role?, :employee_role?
  allow_browser versions: :modern

  private

  def after_sign_in_path_for(_resource)
    admin_root_path
  end

  def set_unread_message_count
    @unread_message_count = Message.inbound.unread.count
  end

  def role_specific_admin_views?
    user_signed_in? && controller_path.start_with?("admin/")
  end

  def prepend_role_specific_admin_views
    role_views_path = Rails.root.join("app/views/admin/roles", current_user.role.to_s)
    prepend_view_path(role_views_path) if role_views_path.directory?
  end

  def unread_message_count
    @unread_message_count.to_i
  end

  def current_role_label
    current_user&.role.to_s.humanize.presence || "Guest"
  end

  def super_admin?
    current_user&.role_super_admin?
  end

  def admin_role?
    current_user&.role_admin?
  end

  def employee_role?
    current_user&.role_employee?
  end

  def can_manage_users?
    current_user&.can_manage_users?
  end

  def require_user_management_access!
    return if can_manage_users?

    redirect_to admin_root_path, alert: "You do not have access to manage users."
  end
end
