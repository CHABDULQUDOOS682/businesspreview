require 'rails_helper'

RSpec.describe "Frontends", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET /design_1" do
    it "returns http success" do
      get design_1_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /abc" do
    it "returns http success" do
      get abc_path
      expect(response).to have_http_status(:success)
    end
  end
end
