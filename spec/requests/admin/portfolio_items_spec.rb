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

  describe "GET /admin/portfolio_items/new" do
    it "returns http success" do
      get new_admin_portfolio_item_path
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

    it "renders new on validation failure" do
      post admin_portfolio_items_path, params: {
        portfolio_item: { title: "", category: "", description: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/portfolio_items/:id/edit" do
    it "returns http success" do
      get edit_admin_portfolio_item_path(portfolio_item)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/portfolio_items/:id" do
    it "updates the portfolio item" do
      patch admin_portfolio_item_path(portfolio_item), params: {
        portfolio_item: { title: "Updated Build" }
      }
      expect(portfolio_item.reload.title).to eq("Updated Build")
      expect(response).to redirect_to(admin_portfolio_items_path)
    end

    it "renders edit on validation failure" do
      patch admin_portfolio_item_path(portfolio_item), params: {
        portfolio_item: { title: "" }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/portfolio_items/:id" do
    it "destroys the portfolio item" do
      expect {
        delete admin_portfolio_item_path(portfolio_item)
      }.to change(PortfolioItem, :count).by(-1)
      expect(response).to redirect_to(admin_portfolio_items_path)
    end
  end

  describe "PATCH /admin/portfolio_items/:id/toggle_active" do
    it "toggles visibility" do
      expect {
        patch toggle_active_admin_portfolio_item_path(portfolio_item)
      }.to change { portfolio_item.reload.active }.from(true).to(false)
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
