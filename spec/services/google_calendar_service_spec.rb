require "rails_helper"

RSpec.describe GoogleCalendarService do
  let(:employee) { create(:user, role: "employee") }
  let(:business) { create(:business) }
  let(:meeting) { create(:meeting, user: employee, business: business) }
  let(:calendar_service) { instance_double(Google::Apis::CalendarV3::CalendarService, authorization: nil) }
  let(:service) { described_class.new(calendar_service: calendar_service) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("GOOGLE_CLIENT_ID").and_return("client-id")
    allow(ENV).to receive(:[]).with("GOOGLE_CLIENT_SECRET").and_return("client-secret")
    allow(ENV).to receive(:[]).with("GOOGLE_REFRESH_TOKEN").and_return("refresh-token")
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("GOOGLE_COMPANY_EMAIL", Meeting::DEFAULT_COMPANY_EMAIL).and_return(Meeting::DEFAULT_COMPANY_EMAIL)
    allow(ENV).to receive(:fetch).with("GOOGLE_CALENDAR_ID", Meeting.company_email).and_return(Meeting::DEFAULT_COMPANY_EMAIL)
  end

  describe "#create_event!" do
    it "creates a calendar event with a meet link" do
      created = Google::Apis::CalendarV3::Event.new(
        id: "evt_123",
        conference_data: Google::Apis::CalendarV3::ConferenceData.new(
          entry_points: [
            Google::Apis::CalendarV3::EntryPoint.new(entry_point_type: "video", uri: "https://meet.google.com/abc-defg-hij")
          ]
        )
      )
      expect(calendar_service).to receive(:insert_event).and_return(created)

      result = service.create_event!(meeting)

      expect(result).to eq(
        google_event_id: "evt_123",
        google_meet_url: "https://meet.google.com/abc-defg-hij"
      )
    end
  end

  describe "#update_event!" do
    it "updates an existing calendar event" do
      meeting.update!(google_event_id: "evt_123", google_meet_url: "https://meet.google.com/abc")
      existing = Google::Apis::CalendarV3::Event.new(
        id: "evt_123",
        conference_data: Google::Apis::CalendarV3::ConferenceData.new(
          entry_points: [
            Google::Apis::CalendarV3::EntryPoint.new(entry_point_type: "video", uri: "https://meet.google.com/abc")
          ]
        )
      )
      updated = existing.dup
      expect(calendar_service).to receive(:get_event).with(Meeting::DEFAULT_COMPANY_EMAIL, "evt_123").and_return(existing)
      expect(calendar_service).to receive(:update_event).and_return(updated)

      result = service.update_event!(meeting)

      expect(result[:google_event_id]).to eq("evt_123")
    end
  end

  describe "#cancel_event!" do
    it "deletes the linked calendar event" do
      meeting.update!(google_event_id: "evt_123")
      expect(calendar_service).to receive(:delete_event).with(Meeting::DEFAULT_COMPANY_EMAIL, "evt_123", send_updates: "all")

      service.cancel_event!(meeting)
    end
  end

  describe "#configured?" do
    it "returns false when credentials are missing" do
      allow(ENV).to receive(:[]).with("GOOGLE_CLIENT_ID").and_return(nil)
      expect(described_class.new.configured?).to be(false)
    end
  end

  describe "#fetch_event" do
    it "returns the Google event" do
      event = Google::Apis::CalendarV3::Event.new(id: "evt_123")
      expect(calendar_service).to receive(:get_event).with(Meeting::DEFAULT_COMPANY_EMAIL, "evt_123").and_return(event)

      expect(service.fetch_event("evt_123")).to eq(event)
    end
  end

  describe "#register_webhook!" do
    it "creates a watch channel when webhook url is configured" do
      allow(ENV).to receive(:[]).with("GOOGLE_CALENDAR_WEBHOOK_URL").and_return("https://example.com/webhooks/google_calendar")
      response = double(id: "channel-1", resource_id: "resource-1", expiration: 2.days.from_now.to_i * 1000)
      expect(calendar_service).to receive(:watch_event).and_return(response)

      expect { service.register_webhook! }.to change(GoogleCalendarChannel, :count).by(1)
    end

    it "returns early when webhook url is blank" do
      allow(ENV).to receive(:[]).with("GOOGLE_CALENDAR_WEBHOOK_URL").and_return(nil)

      expect(calendar_service).not_to receive(:watch_event)
      expect(service.register_webhook!).to be_nil
    end
  end

  describe "lazy calendar service initialization" do
    it "builds a calendar service when one is not injected" do
      allow(ENV).to receive(:[]).with("GOOGLE_CLIENT_ID").and_return("client-id")
      allow(ENV).to receive(:[]).with("GOOGLE_CLIENT_SECRET").and_return("client-secret")
      allow(ENV).to receive(:[]).with("GOOGLE_REFRESH_TOKEN").and_return("refresh-token")

      lazy_service = described_class.new
      calendar = instance_double(Google::Apis::CalendarV3::CalendarService)
      allow(Google::Apis::CalendarV3::CalendarService).to receive(:new).and_return(calendar)
      allow(calendar).to receive(:authorization=)
      allow(Google::Auth::UserRefreshCredentials).to receive(:new).and_return(instance_double(Google::Auth::UserRefreshCredentials))
      created = Google::Apis::CalendarV3::Event.new(id: "evt_lazy")
      expect(calendar).to receive(:insert_event).and_return(created)

      result = lazy_service.create_event!(meeting)
      expect(result[:google_event_id]).to eq("evt_lazy")
    end
  end

  describe "error handling" do
    it "raises when calendar is not configured" do
      allow(ENV).to receive(:[]).with("GOOGLE_CLIENT_ID").and_return(nil)

      expect { service.create_event!(meeting) }.to raise_error(GoogleCalendarService::ConfigurationError)
    end

    it "raises when updating a meeting without a google event id" do
      expect { service.update_event!(meeting) }.to raise_error(GoogleCalendarService::ConfigurationError, /not linked/)
    end

    it "returns early when cancelling a meeting without a google event id" do
      expect(calendar_service).not_to receive(:delete_event)
      expect(service.cancel_event!(meeting)).to be_nil
    end
  end
end
