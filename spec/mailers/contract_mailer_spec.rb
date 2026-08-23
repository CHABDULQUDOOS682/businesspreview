# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContractMailer, type: :mailer do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business, email: "client@example.com") }
  let(:contract) { create(:contract, :sent, business: business, created_by: admin) }

  describe "#sign_request" do
    let(:mail) { described_class.with(contract: contract).sign_request }

    it "sends sign link to the client" do
      expect(mail.to).to eq([ "client@example.com" ])
      expect(mail.subject).to include("Please review and sign")
      expect(mail.body.encoded).to include(contract.access_token)
    end
  end

  describe "#signed_confirmation" do
    let(:contract) { create(:contract, :signed, business: business, created_by: admin) }
    let(:mail) { described_class.with(contract: contract).signed_confirmation }

    it "confirms signature" do
      expect(mail.to).to eq([ "client@example.com" ])
      expect(mail.subject).to include("Signed agreement")
      expect(mail.body.encoded).to include(contract.title)
    end
  end
end
