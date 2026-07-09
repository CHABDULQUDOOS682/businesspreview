require "rails_helper"

RSpec.describe Admin::MeetingsHelper, type: :helper do
  describe "#meeting_status_badge" do
    it "renders a badge for each status" do
      Meeting::STATUSES.each do |status|
        meeting = build(:meeting, status: status)
        html = helper.meeting_status_badge(meeting)
        expect(html).to include(status.humanize)
      end
    end
  end
end
