class GoogleCalendarWebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_unread_message_count
  skip_before_action :verify_authenticity_token

  def create
    GoogleCalendar::WebhookSyncService.new.call(
      channel_id: request.headers["X-Goog-Channel-ID"],
      resource_state: request.headers["X-Goog-Resource-State"]
    )

    head :ok
  end
end
