# frozen_string_literal: true

require "rails_helper"

RSpec.describe Crm::ContractEventNotifier do
  let(:business) do
    create(
      :business,
      email: "client@example.com",
      business_number: "B000123",
      site_api_base_url: "https://dashboard.example.com",
      site_api_secret: "secret"
    )
  end
  let(:admin) { create(:user, :admin) }
  let(:contract) { create(:contract, :sent, business: business, created_by: admin) }
  let(:client) { instance_double(Crm::WebhookClient, configured?: true) }

  before do
    allow(Crm::WebhookClient).to receive(:new).with(business).and_return(client)
    allow(client).to receive(:deliver!)
    Contracts::PdfGenerator.new(contract).attach!
  end

  it "delivers contract_sent with metadata and pdf" do
    described_class.new(contract: contract).call("contract_sent")

    expect(client).to have_received(:deliver!).with(
      hash_including(
        event: "contract_sent",
        external_id: contract.id.to_s,
        title: contract.title,
        status: "sent",
        pdf_base64: a_kind_of(String),
        pdf_filename: a_string_matching(/\.pdf\z/)
      )
    )
  end

  it "delivers contract_signed" do
    contract.update!(
      status: "signed",
      client_signer_name: "Jane",
      client_signed_at: Time.current,
      agency_signer_name: "DevDeBizz",
      agency_signed_at: Time.current
    )

    described_class.new(contract: contract).call("contract_signed")

    expect(client).to have_received(:deliver!).with(hash_including(event: "contract_signed", status: "signed"))
  end

  it "skips when CRM is not configured" do
    allow(client).to receive(:configured?).and_return(false)
    described_class.new(contract: contract).call("contract_sent")
    expect(client).not_to have_received(:deliver!)
  end

  it "ignores unsupported events" do
    described_class.new(contract: contract).call("unknown")
    expect(client).not_to have_received(:deliver!)
  end
end
