require "rails_helper"

RSpec.describe GoogleCalendarWebhooksController, type: :request do
  describe "POST /webhooks/google_calendar" do
    it "accepts webhook notifications" do
      sync = instance_double(GoogleCalendar::WebhookSyncService, call: true)
      expect(GoogleCalendar::WebhookSyncService).to receive(:new).and_return(sync)

      post webhooks_google_calendar_path, headers: {
        "X-Goog-Channel-ID" => "channel-1",
        "X-Goog-Resource-State" => "exists"
      }

      expect(response).to have_http_status(:ok)
      expect(sync).to have_received(:call).with(channel_id: "channel-1", resource_state: "exists")
    end
  end
end
