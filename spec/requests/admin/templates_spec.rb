require 'rails_helper'

RSpec.describe "Admin::Templates", type: :request do
  let(:admin) { create(:user, :admin) }

  before do
    sign_in admin
  end

  describe "GET /admin/templates/:id/preview" do
    it "renders the template preview" do
      get admin_template_preview_path("barber/barber_modern")
      expect(response).to have_http_status(:success)
      expect(response).to render_template("templates/barber/barber_modern")
    end
  end
end
