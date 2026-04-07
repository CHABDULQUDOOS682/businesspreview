class Admin::DashboardController < ApplicationController
  layout "admin"

  def index
    @business_count = Business.count
    @preview_count  = PreviewLink.count
    @total_visits   = PreviewLink.sum(:visit_count)
    @unread_inbound_count = Message.inbound.unread.count
    @admin_count = User.role_admin.count
    @employee_count = User.role_employee.count
    @manageable_user_count = manageable_users.count
    @recent_users = manageable_users.order(created_at: :desc).limit(5)

    @templates = PreviewLink.available_templates

    @recent_businesses = Business.order(created_at: :desc).limit(5)
    @recent_clicks = PreviewLink.where("visit_count > 0").order(updated_at: :desc).limit(5)
  end

  private

  def manageable_users
    return User.all if current_user.role_super_admin?
    return User.managed_by_admin if current_user.role_admin?

    User.none
  end
end
