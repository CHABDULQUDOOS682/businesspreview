# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin contracts", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:employee) { create(:user) }
  let(:business) do
    create(
      :business,
      email: "client@example.com",
      subscription_fee: 50,
      sold_price: 199,
      business_number: "B000555",
      site_api_base_url: "https://dashboard.example.com",
      site_api_secret: "secret"
    )
  end

  describe "GET /admin/businesses/:business_id/contracts/new" do
    it "renders the package form for admins" do
      sign_in admin
      get new_admin_business_contract_path(business)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("New client contract")
      expect(response.body).to include("Agreement type")
    end
  end

  describe "POST /admin/businesses/:business_id/contracts" do
    it "allows admin to create a draft" do
      sign_in admin

      expect {
        post admin_business_contracts_path(business), params: {
          contract: {
            kind: "subscription",
            package_key: "growth",
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
      expect(contract.package_key).to eq("growth")
      expect(contract.document).to be_attached
      expect(response).to redirect_to(admin_business_contract_path(business, contract))
    end

    it "re-renders on validation failure" do
      sign_in admin

      post admin_business_contracts_path(business), params: {
        contract: {
          kind: "subscription",
          title: "",
          client_name: business.name,
          client_email: "bad-email",
          agency_name: "DevDeBizz",
          scope_of_work: "Hosting",
          pricing_terms: "Monthly",
          timeline_terms: "Monthly",
          termination_terms: "30 days"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
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

  describe "member actions" do
    let!(:contract) { create(:contract, business: business, created_by: admin) }

    before { sign_in admin }

    around do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
    end

    it "shows a contract" do
      get admin_business_contract_path(business, contract)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(contract.title)
    end

    it "sends for signature" do
      expect {
        post send_for_signature_admin_business_contract_path(business, contract)
      }.to have_enqueued_job(Crm::NotifyContractJob)

      expect(contract.reload).to be_sent
      expect(response).to redirect_to(admin_business_contract_path(business, contract))
    end

    it "voids a draft" do
      post void_admin_business_contract_path(business, contract)
      expect(contract.reload).to be_void
      expect(response).to redirect_to(admin_business_path(business))
    end

    it "does not void a signed contract" do
      contract.update!(
        status: "signed",
        client_signer_name: "Jane",
        client_signed_at: Time.current,
        agency_signer_name: "DevDeBizz",
        agency_signed_at: Time.current,
        sent_at: Time.current
      )

      post void_admin_business_contract_path(business, contract)
      expect(contract.reload).to be_signed
      expect(response).to redirect_to(admin_business_contract_path(business, contract))
    end

    it "downloads the PDF" do
      Contracts::PdfGenerator.new(contract).attach!
      get download_admin_business_contract_path(business, contract)
      expect(response).to have_http_status(:redirect)
    end

    it "syncs one contract to SitePilot" do
      notifier = instance_double(Crm::ContractEventNotifier, call: true)
      allow(Crm::ContractEventNotifier).to receive(:new).and_return(notifier)

      post sync_to_sitepilot_admin_business_contract_path(business, contract)

      expect(notifier).to have_received(:call).with("contract_sent")
      expect(response).to redirect_to(admin_business_contract_path(business, contract))
    end

    it "alerts when SitePilot is not configured for sync" do
      business.update!(site_api_base_url: nil, site_api_secret: nil)
      post sync_to_sitepilot_admin_business_contract_path(business, contract)
      expect(flash[:alert]).to include("SitePilot is not connected")
    end
  end

  describe "POST sync_all_to_sitepilot" do
    let!(:contract) { create(:contract, business: business, created_by: admin) }

    before { sign_in admin }

    it "syncs all contracts" do
      notifier = instance_double(Crm::ContractEventNotifier, call: true)
      allow(Crm::ContractEventNotifier).to receive(:new).and_return(notifier)

      post sync_all_to_sitepilot_admin_business_contracts_path(business)

      expect(notifier).to have_received(:call).with("contract_sent")
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:notice]).to include("Synced")
    end
  end
end

RSpec.describe "Client contract signing", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:business) { create(:business, email: "client@example.com") }
  let!(:contract) { create(:contract, :sent, business: business, created_by: admin) }

  it "renders the public contract page" do
    get client_contract_path(contract.access_token)
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Draw signature")
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

  it "requires agreement checkbox" do
    post sign_client_contract_path(contract.access_token), params: {
      signer_name: "Jane Client",
      signature_data: "data:image/png;base64,abc"
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(contract.reload).to be_sent
  end

  it "requires a drawn signature" do
    post sign_client_contract_path(contract.access_token), params: {
      signer_name: "Jane Client",
      agree: "1"
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(contract.reload).to be_sent
  end

  it "does not resign an already signed contract" do
    contract.update!(
      status: "signed",
      client_signer_name: "Jane",
      client_signed_at: Time.current,
      agency_signer_name: "DevDeBizz",
      agency_signed_at: Time.current
    )

    post sign_client_contract_path(contract.access_token), params: {
      signer_name: "Other",
      agree: "1",
      signature_data: "data:image/png;base64,abc"
    }

    expect(response).to redirect_to(client_contract_path(contract.access_token))
    expect(flash[:notice]).to include("already signed")
  end
end
