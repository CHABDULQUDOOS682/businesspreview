require "rails_helper"

RSpec.describe "Admin::BusinessImports", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:admin) { create(:user, :admin) }
  let(:employee) { create(:user, role: "employee") }
  let!(:business_import) { create(:business_import, imported_by: super_admin, filename: "businesses.csv") }
  let!(:created_row) do
    create(
      :business_import_row,
      business_import: business_import,
      row_number: 1,
      business_name: "Created Biz",
      phone: "+18005550199",
      status: "created"
    )
  end
  let!(:duplicate_row) do
    create(
      :business_import_row,
      business_import: business_import,
      row_number: 2,
      business_name: "Duplicate Biz",
      phone: "+18005550199",
      status: "duplicate",
      reason: "Phone number already exists in the database"
    )
  end

  describe "GET /admin/business_imports" do
    it "renders for super admins" do
      sign_in super_admin

      get admin_business_imports_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("businesses.csv")
      expect(response.body).to include("Import Reports")
    end

    it "redirects admins" do
      sign_in admin

      get admin_business_imports_path

      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("You do not have permission to access that page.")
    end

    it "redirects employees" do
      sign_in employee

      get admin_business_imports_path

      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to eq("You do not have permission to access that page.")
    end
  end

  describe "GET /admin/business_imports/:id" do
    it "renders the row report for super admins" do
      sign_in super_admin

      get admin_business_import_path(business_import)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Created Biz")
      expect(response.body).to include("Duplicate Biz")
      expect(response.body).to include("Phone number already exists in the database")
    end
  end

  describe "GET /admin/business_imports/:id/download" do
    it "returns a CSV report for super admins" do
      sign_in super_admin

      get download_admin_business_import_path(business_import, format: :csv)

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq("text/csv")
      expect(response.body).to include("Row,Business Name,Phone,Status,Reason")
      expect(response.body).to include("2,Duplicate Biz,+18005550199,duplicate,Phone number already exists in the database")
    end
  end
end
