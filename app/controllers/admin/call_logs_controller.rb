class Admin::CallLogsController < ApplicationController
  layout "admin"

  before_action :require_call_log_access!

  def index
    calls = TwilioCallLogService.new.recent_calls

    @total_calls = calls.size
    @outbound_count = calls.count { |call| call.direction == "outbound" }
    @inbound_count = calls.count { |call| call.direction == "inbound" }

    calls = calls.select { |call| call.direction == params[:direction] } if params[:direction].present?

    if params[:q].present?
      query = params[:q].to_s.downcase
      calls = calls.select do |call|
        [
          call.business&.name,
          call.from_number,
          call.to_number,
          call.sid,
          call.status
        ].compact.any? { |value| value.to_s.downcase.include?(query) }
      end
    end

    @pagy, @call_logs = pagy_array(calls, limit: 25)
  rescue StandardError => e
    @call_logs_error = e.message
    @total_calls = 0
    @outbound_count = 0
    @inbound_count = 0
    @pagy, @call_logs = pagy_array([], limit: 25)
  end

  private

  def require_call_log_access!
    return if super_admin? || admin_role?

    redirect_to admin_root_path, alert: "You do not have access to call logs."
  end
end
