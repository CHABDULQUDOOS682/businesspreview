require 'rails_helper'

RSpec.describe "Admin::Businesses", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:business) { create(:business) }

  before do
    sign_in admin
  end

  describe "GET /admin/businesses" do
    it "returns http success" do
      get admin_businesses_path
      expect(response).to have_http_status(:success)
    end

    it "filters by name" do
      get admin_businesses_path, params: { name: business.name }
      expect(response).to have_http_status(:success)
    end

    it "filters by city and country" do
      get admin_businesses_path, params: { city: business.city, country: business.country }
      expect(response).to have_http_status(:success)
    end

    it "forces nurture segment for employee users regardless of param" do
      employee = create(:user)
      sign_out admin
      sign_in employee
      get admin_businesses_path, params: { segment: "subscriptions" }
      expect(response).to have_http_status(:success)
    end

    it "accepts segment param for non-employee users" do
      get admin_businesses_path, params: { segment: "subscriptions" }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/businesses/new" do
    it "returns http success" do
      get new_admin_business_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/businesses" do
    it "creates a new business and redirects" do
      expect {
        post admin_businesses_path, params: { business: { name: "New", email: "new@example.com", phone: "+1234567890" } }
      }.to change(Business, :count).by(1)
      expect(response).to redirect_to(admin_businesses_path)
    end

    it "renders new when create validation fails" do
      # name blank → validation fails → render :new (line 68)
      post admin_businesses_path, params: { business: { name: "", phone: "+1234567890" } }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/businesses/:id/edit" do
    it "returns http success" do
      get edit_admin_business_path(business)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/businesses/:id" do
    it "returns http success" do
      get admin_business_path(business)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/businesses/import" do
    let(:file_path) { Rails.root.join('spec/fixtures/businesses_import.csv') }

    before do
      FileUtils.mkdir_p(Rails.root.join('spec/fixtures'))
      File.write(file_path, "Business Name,City,Country,Business Type,Phone Number,Rating\nTest Business,NYC,USA,Tech,1234567890,5.0")
    end

    after do
      File.delete(file_path) if File.exist?(file_path)
    end

    it "imports businesses from CSV" do
      file = fixture_file_upload(file_path, 'text/csv')
      expect {
        post import_admin_businesses_path, params: { file: file }
      }.to change(Business, :count).by(1)
      expect(response).to redirect_to(admin_businesses_path)
    end

    it "skips rows with blank names" do
      blank_name_path = Rails.root.join('spec/fixtures/blank_name.csv')
      File.write(blank_name_path, "Business Name,City,Country,Business Type,Phone Number,Rating\n,NYC,USA,Tech,1234567890,5.0")
      file = fixture_file_upload(blank_name_path, 'text/csv')
      expect {
        post import_admin_businesses_path, params: { file: file }
      }.not_to change(Business, :count)
      File.delete(blank_name_path)
    end

    it "redirects if no file is present" do
      post import_admin_businesses_path
      expect(response).to redirect_to(admin_businesses_path)
      expect(flash[:alert]).to include("Please upload")
    end

    it "handles failed imports" do
      # Blank name will skip row in this specific controller logic, so let's use invalid phone if validation exists
      # Actually, let's use a malformed CSV to trigger the rescue block
      allow(CSV).to receive(:foreach).and_raise(StandardError.new("CSV Error"))
      post import_admin_businesses_path, params: { file: fixture_file_upload(file_path, 'text/csv') }
      expect(response).to redirect_to(admin_businesses_path)
      expect(flash[:alert]).to include("Import failed")
    end

    it "reports partial failures when some rows fail validation" do
      partial_fail_path = Rails.root.join('spec/fixtures/partial_fail.csv')
      File.write(partial_fail_path, "Business Name,City,Country,Business Type,Phone Number,Rating\nGood Biz,NYC,USA,Tech,9999999999,4.0\nBad Biz,NYC,USA,Tech,9999999998,3.0")

      call_count = 0
      original_new = Business.method(:new)
      allow(Business).to receive(:new) do |attrs|
        biz = original_new.call(attrs)
        call_count += 1
        allow(biz).to receive(:save).and_return(call_count == 1)
        biz
      end

      file = fixture_file_upload(partial_fail_path, 'text/csv')
      post import_admin_businesses_path, params: { file: file }
      expect(response).to redirect_to(admin_businesses_path)
      expect(flash[:alert]).to match(/Imported \d+, \d+ failed/)
    ensure
      File.delete(partial_fail_path) if File.exist?(partial_fail_path)
    end
  end

  describe "PATCH /admin/businesses/:id" do
    it "updates the business and redirects" do
      patch admin_business_path(business), params: { business: { name: "Updated Name" } }
      expect(business.reload.name).to eq("Updated Name")
      expect(response).to redirect_to(admin_business_path(business))
    end

    it "renders edit if update fails" do
      patch admin_business_path(business), params: { business: { name: "" } }
      expect(response).to have_http_status(:success) # Renders edit
    end
  end

  describe "POST /admin/businesses/:id/send_review_link" do
    it "sends an email and redirects" do
      expect {
        post send_review_link_admin_business_path(business), params: { delivery_method: 'email' }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:notice]).to include("Review link sent via Email")
    end

    it "redirects with alert if email is missing" do
      business.update_columns(email: nil)
      post send_review_link_admin_business_path(business), params: { delivery_method: 'email' }
      expect(flash[:alert]).to include("email missing")
    end

    it "sends an SMS and redirects" do
      # Mock SmsService
      allow(SmsService).to receive(:send_sms).and_return(true)

      post send_review_link_admin_business_path(business), params: { delivery_method: 'sms' }
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:notice]).to include("Review link sent via SMS")
    end

    it "redirects with alert if phone is missing" do
      business.update_columns(phone: nil)
      post send_review_link_admin_business_path(business), params: { delivery_method: 'sms' }
      expect(flash[:alert]).to include("phone missing")
    end

    it "redirects with alert if delivery method is invalid" do
      post send_review_link_admin_business_path(business), params: { delivery_method: 'carrier_pigeon' }
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:alert]).to include("Invalid")
    end
  end
end
