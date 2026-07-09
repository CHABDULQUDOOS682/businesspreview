require "rails_helper"

RSpec.describe Admin::FeedbackStats do
  before do
    create(:feedback, :bug, priority: "critical", status: "pending")
    create(:feedback, feedback_type: "feature_request", status: "in_progress")
    create(:feedback, :completed, feedback_type: "general")
  end

  it "returns global totals" do
    stats = described_class.call

    expect(stats[:total]).to eq(3)
    expect(stats[:pending]).to eq(1)
    expect(stats[:in_progress]).to eq(1)
    expect(stats[:completed]).to eq(1)
    expect(stats[:critical]).to eq(1)
    expect(stats[:feature_requests]).to eq(1)
    expect(stats[:bugs]).to eq(1)
  end
end
