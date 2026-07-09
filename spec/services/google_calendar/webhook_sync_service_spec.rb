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

    it "returns early when Google Calendar is not configured" do
      allow(google_calendar).to receive(:configured?).and_return(false)

      expect { service.call(resource_state: "exists") }.not_to raise_error
    end

    it "touches the matching channel when channel_id is provided" do
      channel = create(:google_calendar_channel, channel_id: "channel-1")
      allow(google_calendar).to receive(:fetch_event)

      expect { service.call(channel_id: "channel-1", resource_state: "exists") }
        .to change { channel.reload.updated_at }
    end

    it "syncs recent events when resource_state is not_exists" do
      meeting = create(:meeting, google_event_id: "evt_123", status: "scheduled")
      event = Google::Apis::CalendarV3::Event.new(status: "cancelled")
      allow(google_calendar).to receive(:fetch_event).with("evt_123").and_return(event)

      service.call(resource_state: "not_exists")

      expect(meeting.reload).to be_cancelled
    end

    it "uses the default sync path when resource_state is unknown" do
      meeting = create(:meeting, google_event_id: "evt_123", status: "scheduled")
      event = Google::Apis::CalendarV3::Event.new(status: "confirmed")
      allow(google_calendar).to receive(:fetch_event).with("evt_123").and_return(event)

      expect { service.call(resource_state: "unknown") }.not_to change { meeting.reload.status }
    end

    it "skips watch registration when an active channel already exists" do
      create(:google_calendar_channel)
      allow(google_calendar).to receive(:register_webhook!)

      service.call(resource_state: "sync")

      expect(google_calendar).not_to have_received(:register_webhook!)
    end

    it "logs and continues when watch registration fails" do
      allow(GoogleCalendarChannel).to receive(:active).and_return(GoogleCalendarChannel.none)
      allow(google_calendar).to receive(:register_webhook!).and_raise(Google::Apis::Error.new("watch failed"))

      expect(Rails.logger).to receive(:warn).with(/watch registration failed/)
      service.call(resource_state: "sync")
    end

    it "skips meetings when Google returns a client error" do
      meeting = create(:meeting, google_event_id: "evt_123", status: "scheduled")
      allow(google_calendar).to receive(:fetch_event).and_raise(Google::Apis::ClientError.new("missing"))

      expect(Rails.logger).to receive(:warn).with(/skipped meeting #{meeting.id}/)
      service.call(resource_state: "exists")
    end
  end
end
