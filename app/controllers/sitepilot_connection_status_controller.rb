# frozen_string_literal: true

class SitepilotConnectionStatusController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_unread_message_count
  skip_before_action :verify_authenticity_token

  def create
    result = SitepilotConnectionStatusService.call(
      business_number: params[:business_number],
      site_external_id: params[:site_external_id],
      site_api_base_url: params[:site_api_base_url],
      request_secret: request.headers["X-Site-Api-Secret"].to_s
    )

    render json: result.payload, status: result.http_status
  end
end
