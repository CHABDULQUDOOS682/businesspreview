require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render json: {
        employee: employee_role?,
        admin: admin_role?,
        super_admin: super_admin?
      }
    end
  end

  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "roles" do
    it "identifies employee" do
      user.update(role: "employee")
      get :index
      expect(JSON.parse(response.body)["employee"]).to be true
    end

    it "identifies admin" do
      user.update(role: "admin")
      get :index
      expect(JSON.parse(response.body)["admin"]).to be true
    end

    it "identifies super_admin" do
      user.update_column(:role, "super_admin")
      get :index
      expect(JSON.parse(response.body)["super_admin"]).to be true
    end
  end
end
