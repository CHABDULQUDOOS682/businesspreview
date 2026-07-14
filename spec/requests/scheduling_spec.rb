require "rails_helper"

RSpec.describe "Scheduling", type: :request do
  let!(:owner) { create(:user, role: "super_admin", email: "super_admin@example.com") }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("SCHEDULING_OWNER_EMAIL").and_return("super_admin@example.com")

    # Wednesday 9:00 AM to 11:00 AM
    AvailabilityRule.create!(
      user: owner,
      day_of_week: 3,
      start_minute: 540,
      end_minute: 660
    )
  end

  describe "GET /schedule" do
    it "renders the scheduling page successfully" do
      get schedule_path
      expect(response).to have_http_status(:success)
    end

    it "falls back to today when the date param is invalid" do
      get schedule_path, params: { date: "not-a-date" }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /schedule/slots" do
    it "renders slot partial successfully" do
      get schedule_slots_path, params: { date: "2026-07-22" }
      expect(response).to have_http_status(:success)
      expect(response.body).to include("9:00 AM")
    end
  end

  describe "GET /schedule/confirmation/:token" do
    it "renders the confirmation page for a booked meeting" do
      meeting = create(:meeting, user: owner, public_token: "abc123confirm")

      get schedule_confirmation_path(token: meeting.public_token)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(meeting.title)
    end
  end

  describe "POST /schedule" do
    let(:slot) { Time.zone.parse("2026-07-22 09:30:00") }

    before do
      sync_result = { google_event_id: "google_123", google_meet_url: "https://meet.google.com/abc-defg-hij" }
      allow_any_instance_of(GoogleCalendarService).to receive(:create_event!).and_return(sync_result)
    end

    it "creates business lead and meeting and redirects to confirmation page" do
      expect {
        post schedule_bookings_path, params: {
          name: "John Doe",
          email: "john@example.com",
          phone: "+15551234567",
          company: "John Corp",
          message: "Let's meet!",
          starts_at: slot.iso8601
        }
      }.to change(Business, :count).by(1).and change(Meeting, :count).by(1)

      meeting = Meeting.last
      expect(response).to redirect_to(schedule_confirmation_path(token: meeting.public_token))

      expect(meeting.client_name).to eq("John Doe")
      expect(meeting.client_phone).to eq("+15551234567")
      expect(meeting.google_event_id).to eq("google_123")
      expect(meeting.google_meet_url).to eq("https://meet.google.com/abc-defg-hij")

      business = Business.last
      expect(business.name).to eq("John Corp")
      expect(business.email).to eq("john@example.com")
      expect(business.phone).to eq("+15551234567")
    end

    it "fails if starts_at is missing" do
      post schedule_bookings_path, params: {
        name: "John Doe",
        email: "john@example.com",
        phone: "+15551234567"
      }
      expect(response).to redirect_to(schedule_path)
      expect(flash[:alert]).to include("Please choose a time slot.")
    end

    it "treats unparseable starts_at as missing" do
      allow(Time.zone).to receive(:parse).and_raise(ArgumentError)

      post schedule_bookings_path, params: {
        name: "John Doe",
        email: "john@example.com",
        phone: "+15551234567",
        starts_at: "broken"
      }

      expect(response).to redirect_to(schedule_path)
      expect(flash[:alert]).to include("Please choose a time slot.")
    end

    it "redirects when the slot was just taken" do
      allow_any_instance_of(MeetingManager).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Meeting.new))

      post schedule_bookings_path, params: {
        name: "John Doe",
        email: "john@example.com",
        phone: "+15551234567",
        starts_at: slot.iso8601
      }

      expect(response).to redirect_to(schedule_path(date: slot.to_date))
      expect(flash[:alert]).to include("just booked")
    end

    it "redirects when Google Calendar sync fails" do
      allow_any_instance_of(MeetingManager).to receive(:create!).and_raise(MeetingManager::SyncError.new("sync failed"))

      post schedule_bookings_path, params: {
        name: "John Doe",
        email: "john@example.com",
        phone: "+15551234567",
        starts_at: slot.iso8601
      }

      expect(response).to redirect_to(schedule_path(date: slot.to_date))
      expect(flash[:alert]).to include("Something went wrong")
    end
  end
end
