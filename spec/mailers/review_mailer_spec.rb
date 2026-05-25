require "rails_helper"

RSpec.describe ReviewMailer, type: :mailer do
  describe "send_link" do
    let(:business) { create(:business, email: "client@example.com") }
    let(:mail) { ReviewMailer.send_link(business) }

    it "renders the headers" do
      expect(mail.subject).to include("We'd love your feedback")
      expect(mail.to).to eq([ "client@example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include(business.review_url)
    end
  end
end
