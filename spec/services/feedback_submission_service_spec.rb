require "rails_helper"

RSpec.describe FeedbackSubmissionService do
  let(:user) { create(:user, role: "employee") }

  it "creates feedback with default priority and status" do
    feedback = described_class.new(
      user: user,
      attributes: {
        title: "Add export button",
        description: "Need CSV export on businesses page",
        feedback_type: "feature_request"
      }
    ).call

    expect(feedback).to be_persisted
    expect(feedback.priority).to eq("medium")
    expect(feedback.status).to eq("pending")
    expect(feedback.user).to eq(user)
  end
end
