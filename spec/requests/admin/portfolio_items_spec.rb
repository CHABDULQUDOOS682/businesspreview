require "rails_helper"

RSpec.describe "Admin::PortfolioItems", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:portfolio_item) { create(:portfolio_item) }

  before { sign_in admin }

  describe "GET /admin/portfolio_items" do
    it "returns http success" do
      get admin_portfolio_items_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/portfolio_items" do
    it "creates a portfolio item" do
      expect {
        post admin_portfolio_items_path, params: {
          portfolio_item: {
            title: "Clinic Site",
            category: "Clinic",
            description: "Appointment-focused clinic website.",
            metric: "Appointments",
            accent_color: "from-cyan-400/30",
            position: 10,
            active: true
          }
        }
      }.to change(PortfolioItem, :count).by(1)

      expect(response).to redirect_to(admin_portfolio_items_path)
    end
  end

  describe "employee access" do
    let(:employee) { create(:user, role: "employee") }

    before { sign_in employee }

    it "redirects employees away" do
      get admin_portfolio_items_path
      expect(response).to redirect_to(admin_root_path)
    end
  end
end
