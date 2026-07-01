require "rails_helper"
require "tempfile"

RSpec.describe "Admin::Businesses", type: :request do
  # Include ActiveJob matchers to cleanly verify .deliver_later execution
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:employee) { create(:user, role: "employee") }
  let(:business) { create(:business, email: "devdebizz@gmail.com", phone: "+1234567890") }

  before do
    sign_in admin
  end

  describe "GET /admin/businesses" do
    let!(:nurture_biz) { create(:business, name: "Nurture Biz", niche: "Retail", city: "NYC", country: "USA", sold_price: nil, subscription_fee: nil, subscription: false) }
    let!(:purchased_biz) { create(:business, name: "Purchased Biz", niche: "Tech", city: "SF", country: "USA", sold_price: 1000, subscription_fee: nil, subscription: false) }
    let!(:subscription_biz) { create(:business, name: "Sub Biz", niche: "SaaS", city: "Austin", country: "USA", sold_price: nil, subscription_fee: 99, subscription: true) }

    context "when logged in as admin" do
      it "returns success and lists nurture businesses by default" do
        get admin_businesses_path
        expect(response).to have_http_status(:success)
        expect(assigns(:businesses)).to include(nurture_biz)
        expect(assigns(:businesses)).not_to include(purchased_biz)
        expect(assigns(:businesses)).not_to include(subscription_biz)
      end

      it "lists purchased businesses when segment is purchased" do
        get admin_businesses_path, params: { segment: "purchased" }
        expect(response).to have_http_status(:success)
        expect(assigns(:businesses)).to include(purchased_biz)
        expect(assigns(:businesses)).not_to include(nurture_biz)
        expect(response.body).to include(admin_communication_path(purchased_biz.phone))
        expect(response.body).to include("Chat")
      end

      it "lists subscription businesses when segment is subscriptions" do
        get admin_businesses_path, params: { segment: "subscriptions" }
        expect(response).to have_http_status(:success)
        expect(assigns(:businesses)).to include(subscription_biz)
        expect(response.body).to include(admin_communication_path(subscription_biz.phone))
        expect(response.body).to include("Chat")
      end

      it "filters by name" do
        get admin_businesses_path, params: { name: "Nurture" }
        expect(assigns(:businesses)).to include(nurture_biz)
        expect(assigns(:businesses)).not_to include(purchased_biz)
      end

      it "filters by niche" do
        get admin_businesses_path, params: { niche: "Retail" }
        expect(assigns(:businesses)).to include(nurture_biz)
        expect(assigns(:businesses)).not_to include(purchased_biz)
      end

      it "filters by city" do
        get admin_businesses_path, params: { city: "NYC" }
        expect(assigns(:businesses)).to include(nurture_biz)
      end

      it "filters by country" do
        get admin_businesses_path, params: { country: "USA" }
        expect(assigns(:businesses)).to include(nurture_biz)
      end
    end

    context "when logged in as employee" do
      before do
        sign_in employee
      end

      it "forces segment to nurture even if other segment is requested" do
        get admin_businesses_path, params: { segment: "purchased" }
        expect(response).to have_http_status(:success)
        expect(assigns(:segment)).to eq("nurture")
        expect(assigns(:businesses)).to include(nurture_biz)
        expect(assigns(:businesses)).not_to include(purchased_biz)
      end
    end
  end

  describe "GET /admin/businesses/new" do
    it "renders the new form" do
      get new_admin_business_path
      expect(response).to have_http_status(:success)
      expect(assigns(:business)).to be_a_new(Business)
    end
  end

  describe "POST /admin/businesses" do
    context "with valid parameters" do
      it "creates a new Business and redirects" do
        expect {
          post admin_businesses_path, params: { business: { name: "New Biz", phone: "+111222333" } }
        }.to change(Business, :count).by(1)

        expect(response).to redirect_to(admin_businesses_path)
        expect(flash[:notice]).to eq("Business created!")
      end

      it "assigns the seller for commission attribution" do
        post admin_businesses_path, params: { business: { name: "Sold Biz", phone: "+111222333", sold_by_id: employee.id } }

        expect(Business.last.sold_by).to eq(employee)
      end
    end

    context "with invalid parameters" do
      it "does not create a business and renders new" do
        expect {
          post admin_businesses_path, params: { business: { name: "", phone: "" } }
        }.not_to change(Business, :count)

        expect(response).to have_http_status(:success) # render :new returns 200 OK
      end
    end
  end

  describe "GET /admin/businesses/:id" do
    it "renders the show view" do
      get admin_business_path(business)
      expect(response).to have_http_status(:success)
      expect(assigns(:business)).to eq(business)
    end

    it "includes a chat link for subscription businesses" do
      subscription_biz = create(
        :business,
        name: "Sub Show Biz",
        phone: "+15559876543",
        subscription: true,
        subscription_fee: 99
      )

      get admin_business_path(subscription_biz)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(admin_communication_path(subscription_biz.phone))
      expect(response.body).to include("Chat")
    end
  end

  describe "GET /admin/businesses/:id/edit" do
    it "renders the edit view" do
      get edit_admin_business_path(business)
      expect(response).to have_http_status(:success)
      expect(assigns(:business)).to eq(business)
    end
  end

  describe "PATCH /admin/businesses/:id" do
    context "with valid parameters" do
      it "updates the business and redirects" do
        patch admin_business_path(business), params: { business: { name: "Updated Name" } }
        expect(business.reload.name).to eq("Updated Name")
        expect(response).to redirect_to(admin_business_path(business))
        expect(flash[:notice]).to eq("Business updated!")
      end

      it "updates the seller for commission attribution" do
        patch admin_business_path(business), params: { business: { sold_by_id: employee.id } }

        expect(business.reload.sold_by).to eq(employee)
      end
    end

    context "with invalid parameters" do
      it "does not update the business and renders edit" do
        patch admin_business_path(business), params: { business: { name: "" } }
        expect(business.reload.name).not_to eq("")
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /admin/businesses/import" do
    before do
      sign_in super_admin
    end

    context "when logged in as admin" do
      before do
        sign_in admin
      end

      it "redirects without importing" do
        post import_admin_businesses_path

        expect(response).to redirect_to(admin_root_path)
        expect(flash[:alert]).to eq("You do not have permission to access that page.")
      end
    end

    context "when file is missing" do
      it "redirects and sets an alert" do
        post import_admin_businesses_path
        expect(response).to redirect_to(admin_businesses_path)
        expect(flash[:alert]).to eq("Please upload a CSV file.")
      end
    end

    context "with a valid CSV file" do
      let(:csv_file) do
        file = Tempfile.new([ "import", ".csv" ])
        file.write("Business Name,City,Country,Business Type,Phone Number,Rating\n")
        file.write("CSV Biz 1,Chicago,USA,Consulting,18005550199,4.8\n")
        file.write(",Skipped Biz,USA,Consulting,18005550199,4.8\n") # name blank, should skip
        file.close
        Rack::Test::UploadedFile.new(file.path, "text/csv")
      end

      it "imports valid businesses and redirects with notice" do
        expect {
          post import_admin_businesses_path, params: { file: csv_file }
        }.to change(Business, :count).by(1)

        import = BusinessImport.last
        expect(response).to redirect_to(admin_business_import_path(import))
        expect(flash[:notice]).to eq("Imported 1 of 2 rows (0 duplicates, 1 failed).")
      end
    end

    context "with a duplicate phone in CSV rows" do
      let(:csv_file) do
        file = Tempfile.new([ "import", ".csv" ])
        file.write("Business Name,City,Country,Business Type,Phone Number,Rating\n")
        file.write("Existing CSV Biz,Chicago,USA,Consulting,+1 (800) 555-0199,4.8\n")
        file.close
        Rack::Test::UploadedFile.new(file.path, "text/csv")
      end

      before do
        create(:business, phone: "+18005550199")
      end

      it "does not create a duplicate business and redirects to the import report" do
        expect {
          post import_admin_businesses_path, params: { file: csv_file }
        }.not_to change(Business, :count)

        import = BusinessImport.last
        expect(response).to redirect_to(admin_business_import_path(import))
        expect(flash[:notice]).to eq("Imported 0 of 1 rows (1 duplicates, 0 failed).")
      end
    end

    context "when an exception occurs during parsing" do
      let(:csv_file) do
        file = Tempfile.new([ "import", ".csv" ])
        file.write("some invalid content")
        file.close
        Rack::Test::UploadedFile.new(file.path, "text/csv")
      end

      before do
        allow(CSV).to receive(:foreach).and_raise(StandardError.new("Malformed CSV file"))
      end

      it "rescues standard errors and redirects with alert" do
        post import_admin_businesses_path, params: { file: csv_file }
        expect(response).to redirect_to(admin_businesses_path)
        expect(flash[:alert]).to eq("Import failed: Malformed CSV file")
      end
    end
  end

  describe "POST /admin/businesses/:id/send_review_link" do
    context "with email delivery method" do
      context "when business has an email" do
        it "sends an email and redirects" do
          expect {
            post send_review_link_admin_business_path(business), params: { delivery_method: 'email' }
          }.to have_enqueued_mail(ReviewMailer, :send_link).with(business)

          expect(response).to redirect_to(admin_business_path(business))
          expect(flash[:notice]).to eq("Review link sent via Email.")
        end
      end

      context "when business email is missing" do
        before do
          business.update!(email: nil)
        end

        it "does not send and redirects with alert" do
          expect {
            post send_review_link_admin_business_path(business), params: { delivery_method: 'email' }
          }.not_to have_enqueued_mail(ReviewMailer, :send_link)

          expect(response).to redirect_to(admin_business_path(business))
          expect(flash[:alert]).to eq("Business email missing.")
        end
      end
    end

    context "with sms delivery method" do
      context "when business has a phone number" do
        it "sends an SMS and redirects" do
          allow(SmsService).to receive(:send_sms).and_return(true)

          expect {
            post send_review_link_admin_business_path(business), params: { delivery_method: 'sms' }
          }.to change(Message, :count).by(1)

          expect(response).to redirect_to(admin_business_path(business))
          expect(flash[:notice]).to eq("Review link sent via SMS.")
        end
      end

      context "when business phone is missing" do
        before do
          # Skip validations to make phone nil
          business.update_attribute(:phone, nil)
        end

        it "does not send and redirects with alert" do
          expect {
            post send_review_link_admin_business_path(business), params: { delivery_method: 'sms' }
          }.not_to change(Message, :count)

          expect(response).to redirect_to(admin_business_path(business))
          expect(flash[:alert]).to eq("Business phone missing.")
        end
      end
    end

    context "with an invalid delivery method" do
      it "redirects with alert" do
        post send_review_link_admin_business_path(business), params: { delivery_method: 'carrier_pigeon' }
        expect(response).to redirect_to(admin_business_path(business))
        expect(flash[:alert]).to eq("Invalid delivery method.")
      end
    end
  end
end
