require "rails_helper"

RSpec.describe ContactMailer, type: :mailer do
  describe "#new_lead_alert" do
    let(:params) do
      {
        first_name: "Jane",
        last_name: "Doe",
        email: "jane.doe@example.com",
        company: "Innovate LLC",
        service_interest: "Web Design",
        message: "Hello, I am interested in your services."
      }
    end

    let(:mail) { ContactMailer.new_lead_alert(params) }

    it "renders the headers" do
      expect(mail.subject).to eq("🔥 New Lead Inbound: Jane Doe - Web Design")
      expect(mail.to).to eq([ "developer.qudoos@gmail.com" ])
      expect(mail.from).to eq([ "hello@devdebizz.com" ])
    end

    it "renders the body with params details" do
      expect(mail.body.encoded).to include("Jane")
      expect(mail.body.encoded).to include("Doe")
      expect(mail.body.encoded).to include("jane.doe@example.com")
      expect(mail.body.encoded).to include("Innovate LLC")
      expect(mail.body.encoded).to include("Web Design")
      expect(mail.body.encoded).to include("Hello, I am interested in your services.")
    end
  end
end
