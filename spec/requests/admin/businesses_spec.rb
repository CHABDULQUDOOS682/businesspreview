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

  describe "employee business email editing" do
    before do
      sign_in employee
    end

    it "renders the email edit form" do
      get edit_admin_business_path(business)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Edit Business Email")
      expect(response.body).not_to include("Sold Price")
    end

    it "updates only the business email" do
      patch admin_business_path(business), params: {
        business: {
          email: "updated-client@example.com",
          name: "Hacked Name",
          sold_price: 9999
        }
      }

      business.reload
      expect(business.email).to eq("updated-client@example.com")
      expect(business.name).not_to eq("Hacked Name")
      expect(business.sold_price).not_to eq(9999)
      expect(response).to redirect_to(admin_business_path(business))
      expect(flash[:notice]).to eq("Business email updated!")
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
          post admin_businesses_path, params: {
            business: {
              name: "New Biz",
              country: "USA",
              city: "Birmingham",
              business_location: "https://www.google.com/maps/place/New+Biz",
              niche: "Barber shop",
              email: "new@example.com",
              phone: "+111222333",
              rating: "4.8",
              website_url: "https://new.example"
            }
          }
        }.to change(Business, :count).by(1)

        expect(response).to redirect_to(admin_businesses_path)
        expect(flash[:notice]).to eq("Business created!")
        expect(Business.last).to have_attributes(
          business_location: "https://www.google.com/maps/place/New+Biz",
          niche: "Barber shop",
          email: "new@example.com",
          website_url: "https://new.example"
        )
      end

      it "assigns the seller for commission attribution" do
        post admin_businesses_path, params: { business: { name: "Sold Biz", phone: "+111222333", sold_by_id: employee.id } }

        expect(Business.last.sold_by).to eq(employee)
      end

      it "keeps sold_by unassigned when Unassigned is selected" do
        post admin_businesses_path, params: { business: { name: "Unassigned Biz", phone: "+111222334", sold_by_id: "" } }

        expect(Business.last.sold_by).to be_nil
      end
    end

    context "with invalid parameters" do
      it "does not create a business and renders new" do
        expect {
          post admin_businesses_path, params: { business: { name: "", phone: "" } }
        }.not_to change(Business, :count)

        expect(response).to have_http_status(:unprocessable_entity)
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
        patch admin_business_path(business), params: {
          business: {
            name: "Updated Name",
            business_location: "https://www.google.com/maps/place/Updated",
            website_url: "https://updated.example"
          }
        }
        expect(business.reload.name).to eq("Updated Name")
        expect(business.business_location).to eq("https://www.google.com/maps/place/Updated")
        expect(business.website_url).to eq("https://updated.example")
        expect(response).to redirect_to(admin_business_path(business))
        expect(flash[:notice]).to eq("Business updated!")
      end

      it "updates the seller for commission attribution" do
        patch admin_business_path(business), params: { business: { sold_by_id: employee.id } }

        expect(business.reload.sold_by).to eq(employee)
      end

      it "clears sold_by when Unassigned is selected" do
        business.update!(sold_by: employee)

        patch admin_business_path(business), params: { business: { sold_by_id: "" } }

        expect(business.reload.sold_by).to be_nil
      end

      it "keeps sold_by unassigned when updating other fields" do
        business.update!(sold_by: nil)

        patch admin_business_path(business), params: { business: { name: "Still Unassigned", sold_by_id: "" } }

        expect(business.reload).to have_attributes(name: "Still Unassigned", sold_by: nil)
      end
    end

    context "with invalid parameters" do
      it "does not update the business and renders edit" do
        patch admin_business_path(business), params: { business: { name: "" } }
        expect(business.reload.name).not_to eq("")
        expect(response).to have_http_status(:unprocessable_entity)
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
        file.write("Country,City,Business Location,Business Name,Rating,OutOff,Business Type,Email,Phone Number,Website\n")
        file.write("USA,Chicago,https://maps.example/csv-biz,CSV Biz 1,4.8,-10,Consulting,csv@example.com,18005550199,https://csv.example\n")
        file.write("USA,Chicago,https://maps.example/skipped,,4.8,-10,Consulting,skipped@example.com,18005550199,https://skipped.example\n") # name blank, should fail
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
        expect(Business.find_by(phone: "+18005550199")).to have_attributes(
          business_location: "https://maps.example/csv-biz",
          email: "csv@example.com",
          website_url: "https://csv.example"
        )
      end
    end

    context "with a duplicate phone in CSV rows" do
      let(:csv_file) do
        file = Tempfile.new([ "import", ".csv" ])
        file.write("Country,City,Business Location,Business Name,Rating,OutOff,Business Type,Email,Phone Number,Website\n")
        file.write("USA,Chicago,https://maps.example/existing,Existing CSV Biz,4.8,-10,Consulting,existing@example.com,+1 (800) 555-0199,https://existing.example\n")
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
    around do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
      ActiveJob::Base.queue_adapter = original_adapter
    end
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

    context "when logged in as an employee" do
      before { sign_in employee }

      it "redirects employees away from send_review_link" do
        post send_review_link_admin_business_path(business), params: { delivery_method: "email" }
        expect(response).to redirect_to(admin_root_path)
      end
    end
  end

  describe "POST /admin/businesses/:id/verify_phone" do
    include ActiveJob::TestHelper

    around do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      clear_enqueued_jobs
      example.run
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
    end

    context "when logged in as super_admin" do
      before { sign_in super_admin }

      it "queues PhoneLookupJob and redirects with notice" do
        expect {
          post verify_phone_admin_business_path(business)
        }.to have_enqueued_job(PhoneLookupJob).with(business.id)

        expect(response).to redirect_to(admin_business_path(business))
        follow_redirect!
        expect(response.body).to include("Number verification queued.")
      end

      it "shows the verify button and badge on the show page" do
        get admin_business_path(business)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Verify Number")
        expect(response.body).to include("Phone Line Type")
        expect(response.body).to include("Not checked")
      end
    end

    context "when logged in as admin" do
      before { sign_in admin }

      it "denies access" do
        expect {
          post verify_phone_admin_business_path(business)
        }.not_to have_enqueued_job(PhoneLookupJob)

        expect(response).to redirect_to(admin_root_path)
      end

      it "does not show the verify button on the show page" do
        get admin_business_path(business)
        expect(response.body).not_to include("Verify Number")
        expect(response.body).not_to include("Phone Line Type")
      end
    end

    context "when logged in as employee" do
      before { sign_in employee }

      it "denies access" do
        expect {
          post verify_phone_admin_business_path(business)
        }.not_to have_enqueued_job(PhoneLookupJob)

        expect(response).to redirect_to(admin_root_path)
      end
    end
  end
end
