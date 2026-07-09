require "rails_helper"

RSpec.describe MeetingManager do
  let(:employee) { create(:user, role: "employee") }
  let(:business) { create(:business) }
  let(:meeting) { build(:meeting, user: employee, business: business) }
  let(:google_calendar) { instance_double(GoogleCalendarService) }
  let(:manager) { described_class.new(google_calendar: google_calendar) }

  describe "#create!" do
    it "persists the meeting and stores google event details" do
      allow(google_calendar).to receive(:create_event!).and_return(
        google_event_id: "evt_123",
        google_meet_url: "https://meet.google.com/abc"
      )

      result = manager.create!(meeting)

      expect(result).to be_persisted
      expect(result.google_event_id).to eq("evt_123")
      expect(result.google_meet_url).to eq("https://meet.google.com/abc")
    end
  end

  describe "#update!" do
    it "updates the meeting and syncs google when linked" do
      meeting.save!
      meeting.update!(google_event_id: "evt_123")
      allow(google_calendar).to receive(:update_event!).and_return(
        google_event_id: "evt_123",
        google_meet_url: "https://meet.google.com/updated"
      )

      manager.update!(meeting, title: "Updated title")

      expect(meeting.reload.title).to eq("Updated title")
      expect(meeting.google_meet_url).to eq("https://meet.google.com/updated")
    end
  end

  describe "#cancel!" do
    it "cancels the google event and marks the meeting cancelled" do
      meeting.save!
      meeting.update!(google_event_id: "evt_123")
      allow(google_calendar).to receive(:cancel_event!)

      manager.cancel!(meeting)

      expect(meeting.reload).to be_cancelled
      expect(google_calendar).to have_received(:cancel_event!).with(meeting)
    end
  end
end
