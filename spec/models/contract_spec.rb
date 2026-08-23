# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contract, type: :model do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business, email: "client@example.com", subscription_fee: 50, sold_price: 199) }

  it "applies templates for subscription and project kinds" do
    subscription = build(:contract, business: business, created_by: admin, scope_of_work: nil, pricing_terms: nil, timeline_terms: nil, termination_terms: nil, title: nil)
    subscription.apply_template!("subscription")
    expect(subscription.title).to be_present
    expect(subscription.scope_of_work).to include("hosting")

    project = build(:contract, :project, business: business, created_by: admin, scope_of_work: nil, pricing_terms: nil, timeline_terms: nil, termination_terms: nil, title: nil)
    project.apply_template!("one_time_project")
    expect(project.title).to be_present
    expect(project.pricing_terms).to be_present
  end

  it "exposes labels and amount helpers" do
    contract = create(:contract, business: business, created_by: admin, package_key: "growth", amount_cents: 5000)
    expect(contract.kind_label).to eq("Monthly subscription")
    expect(contract.status_label).to eq("Draft")
    expect(contract.package_label).to eq("Growth")
    expect(contract.amount).to eq(50.0)
    expect(contract).to be_draft
    expect(contract).to be_signable
  end

  it "marks sent and void" do
    contract = create(:contract, business: business, created_by: admin)
    contract.mark_sent!
    expect(contract).to be_sent
    expect(contract.sent_at).to be_present

    contract.mark_void!
    expect(contract).to be_void
  end

  it "signs with drawn signature image" do
    contract = create(:contract, :sent, business: business, created_by: admin)
    signature = "data:image/png;base64,#{Base64.strict_encode64("png-bytes")}"

    contract.sign_by_client!(
      name: "Jane Client",
      ip: "1.2.3.4",
      user_agent: "RSpec",
      signature_data: signature
    )

    expect(contract).to be_signed
    expect(contract.client_signer_name).to eq("Jane Client")
    expect(contract.client_signature).to be_attached
  end

  it "rejects signing without a signature image" do
    contract = create(:contract, :sent, business: business, created_by: admin)
    expect {
      contract.sign_by_client!(name: "Jane", ip: "1.1.1.1", user_agent: "x", signature_data: nil)
    }.to raise_error(ArgumentError, /signature/i)
  end
end
