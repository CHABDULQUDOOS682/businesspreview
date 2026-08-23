# frozen_string_literal: true

require "rails_helper"

RSpec.describe Crm::NotifyContractJob do
  let(:business) { create(:business, email: "client@example.com") }
  let(:admin) { create(:user, :admin) }
  let(:contract) { create(:contract, :sent, business: business, created_by: admin) }
  let(:notifier) { instance_double(Crm::ContractEventNotifier, call: true) }

  it "notifies through ContractEventNotifier" do
    allow(Crm::ContractEventNotifier).to receive(:new).with(contract: contract).and_return(notifier)

    described_class.new.perform(contract.id, "contract_sent")

    expect(notifier).to have_received(:call).with("contract_sent")
  end
end

RSpec.describe Crm::SyncBusinessContractsJob do
  let(:business) do
    create(
      :business,
      email: "client@example.com",
      business_number: "B000321",
      site_api_base_url: "https://dashboard.example.com",
      site_api_secret: "secret"
    )
  end
  let(:admin) { create(:user, :admin) }
  let!(:draft) { create(:contract, business: business, created_by: admin) }
  let!(:signed) { create(:contract, :signed, business: business, created_by: admin) }
  let!(:voided) { create(:contract, business: business, created_by: admin, status: "void") }
  let(:client) { instance_double(Crm::WebhookClient, configured?: true) }

  before do
    allow(Crm::WebhookClient).to receive(:new).with(business).and_return(client)
    allow(client).to receive(:deliver!)
    allow(Contracts::PdfGenerator).to receive_message_chain(:new, :attach!)
  end

  it "syncs non-void contracts" do
    allow(Crm::ContractEventNotifier).to receive(:new).and_wrap_original do |method, **kwargs|
      notifier = method.call(**kwargs)
      allow(notifier).to receive(:call)
      notifier
    end

    described_class.new.perform(business.id)

    expect(Crm::ContractEventNotifier).to have_received(:new).with(contract: draft)
    expect(Crm::ContractEventNotifier).to have_received(:new).with(contract: signed)
    expect(Crm::ContractEventNotifier).not_to have_received(:new).with(contract: voided)
  end

  it "raises configuration error when CRM is not configured" do
    allow(client).to receive(:configured?).and_return(false)

    expect {
      described_class.new.perform(business.id)
    }.to raise_error(Crm::WebhookClient::ConfigurationError)
  end
end
