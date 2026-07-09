require "rails_helper"

RSpec.describe Admin::MeetingsHelper, type: :helper do
  let(:meeting) { build(:meeting, starts_at: Time.zone.local(2026, 7, 15, 10, 0), duration_minutes: 30) }
  let(:business) { create(:business) }

  describe "#meeting_status_badge" do
    it "renders a badge for each status" do
      Meeting::STATUSES.each do |status|
        meeting = build(:meeting, status: status)
        html = helper.meeting_status_badge(meeting)
        expect(html).to include(status.humanize)
      end
    end
  end

  describe "#meeting_datetime" do
    it "formats the meeting start time" do
      expect(helper.meeting_datetime(meeting)).to include("Jul 15, 2026")
    end
  end

  describe "#meeting_time_range" do
    it "formats the meeting time range" do
      expect(helper.meeting_time_range(meeting)).to include("10:00 AM")
      expect(helper.meeting_time_range(meeting)).to include("10:30 AM")
    end
  end

  describe "#meeting_calendar_day_classes" do
    it "highlights the selected day and today" do
      classes = helper.meeting_calendar_day_classes(Date.current, Date.current, Date.current.beginning_of_month)
      expect(classes).to include("ring-2")
    end
  end

  describe "#meeting_businesses_json" do
    it "serializes business data for the schedule form" do
      json = helper.meeting_businesses_json([ business ])
      expect(json).to include(business.name)
      expect(json).to include(business.email)
    end
  end

  describe "#calendar_nav_params" do
    it "preserves filter params while navigating the calendar" do
      allow(helper).to receive(:params).and_return(
        ActionController::Parameters.new(employee_id: "1", q: "client")
      )

      params = helper.calendar_nav_params(month: Date.current, date: Date.current)
      expect(params).to include(month: Date.current.strftime("%Y-%m"), date: Date.current, employee_id: "1", q: "client")
    end
  end
end
