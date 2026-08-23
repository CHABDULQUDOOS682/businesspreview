# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin contracts", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:employee) { create(:user) }
  let(:business) { create(:business, email: "client@example.com") }

  describe "POST /admin/businesses/:business_id/contracts" do
    it "allows admin to create a draft" do
      sign_in admin

      expect {
        post admin_business_contracts_path(business), params: {
          contract: {
            kind: "subscription",
            title: "Partnership agreement",
            client_name: business.name,
            client_email: business.email,
            agency_name: "DevDeBizz",
            scope_of_work: "Hosting and updates",
            pricing_terms: "$50 / month",
            timeline_terms: "Monthly",
            termination_terms: "30 days notice",
            amount_dollars: "50"
          }
        }
      }.to change(Contract, :count).by(1)

      contract = Contract.last
      expect(contract.amount_cents).to eq(5000)
      expect(contract.document).to be_attached
      expect(response).to redirect_to(admin_business_contract_path(business, contract))
    end

    it "blocks employees" do
      sign_in employee

      post admin_business_contracts_path(business), params: {
        contract: {
          kind: "subscription",
          title: "Partnership agreement",
          client_name: business.name,
          client_email: business.email,
          agency_name: "DevDeBizz",
          scope_of_work: "Hosting",
          pricing_terms: "Monthly",
          timeline_terms: "Monthly",
          termination_terms: "30 days"
        }
      }

      expect(response).to redirect_to(admin_root_path)
      expect(Contract.count).to eq(0)
    end
  end
end

RSpec.describe "Client contract signing", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business, email: "client@example.com") }
  let!(:contract) do
    business.contracts.create!(
      kind: "one_time_project",
      status: "sent",
      title: "Project agreement",
      client_name: business.name,
      client_email: business.email,
      agency_name: "DevDeBizz",
      scope_of_work: "Build site",
      pricing_terms: "$199",
      timeline_terms: "2-3 days",
      termination_terms: "Breach notice",
      created_by: admin,
      sent_at: Time.current
    )
  end

  it "signs via magic link with drawn signature" do
    signature = "data:image/png;base64,#{Base64.strict_encode64("fake-png-bytes")}"

    post sign_client_contract_path(contract.access_token), params: {
      signer_name: "Jane Client",
      agree: "1",
      signature_data: signature
    }

    expect(response).to redirect_to(client_contract_path(contract.access_token))
    contract.reload
    expect(contract).to be_signed
    expect(contract.client_signer_name).to eq("Jane Client")
    expect(contract.client_signature).to be_attached
    expect(contract.document).to be_attached
  end
end
