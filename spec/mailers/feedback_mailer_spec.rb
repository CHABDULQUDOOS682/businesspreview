require "rails_helper"

RSpec.describe FeedbackMailer, type: :mailer do
  let(:feedback) { create(:feedback, status: "under_review") }

  describe "#status_changed" do
    let(:mail) { described_class.status_changed(feedback) }

    it "sends to the feedback creator" do
      expect(mail.to).to eq([ feedback.user.email ])
      expect(mail.subject).to include(feedback.title)
      expect(mail.body.encoded).to include("Under review")
    end
  end
end
