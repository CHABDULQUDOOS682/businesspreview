class Admin::CallLogsController < ApplicationController
  layout "admin"

  before_action :require_call_log_access!

  def index
    scope = CallLog.recent_first.includes(:user, :business)

    @total_calls = scope.count
    @outbound_count = scope.outbound.count
    @inbound_count = scope.inbound.count

    scope = scope.where(direction: params[:direction]) if params[:direction].present?
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?

    if params[:q].present?
      query = "%#{params[:q].to_s.strip}%"
      scope = scope.left_joins(:user, :business).where(
        "businesses.name ILIKE :q OR call_logs.from_number ILIKE :q OR call_logs.to_number ILIKE :q OR call_logs.twilio_call_sid ILIKE :q OR call_logs.status ILIKE :q OR users.name ILIKE :q OR users.email ILIKE :q",
        q: query
      )
    end

    @employee_options = User.where(id: CallLog.select(:user_id).where.not(user_id: nil).distinct)
                            .order(:email)
    @pagy, @call_logs = pagy(scope, limit: 25)
  end

  private

  def require_call_log_access!
    return if super_admin? || admin_role?

    redirect_to admin_root_path, alert: "You do not have access to call logs."
  end
end
