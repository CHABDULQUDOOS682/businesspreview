require "rails_helper"

RSpec.describe GoogleCalendar::WebhookSyncService do
  let(:google_calendar) { instance_double(GoogleCalendarService, configured?: true) }
  let(:service) { described_class.new(google_calendar: google_calendar) }

  describe "#call" do
    it "marks a meeting cancelled when Google cancels the event" do
      meeting = create(:meeting, google_event_id: "evt_123", status: "scheduled")
      event = Google::Apis::CalendarV3::Event.new(status: "cancelled")
      allow(google_calendar).to receive(:fetch_event).with("evt_123").and_return(event)

      service.call(resource_state: "exists")

      expect(meeting.reload).to be_cancelled
    end

    it "registers a watch channel during sync notifications" do
      allow(google_calendar).to receive(:register_webhook!)
      service.call(channel_id: "channel-1", resource_state: "sync")
      expect(google_calendar).to have_received(:register_webhook!)
    end
  end
end
