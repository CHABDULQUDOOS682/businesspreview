require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    skip_before_action :authenticate_user!, raise: false

    before_action :require_user_management_access!, only: :manage_users
    before_action :require_super_admin!, only: :super_only

    def index
      render json: {
        employee: employee_role?,
        admin: admin_role?,
        super_admin: super_admin?,
        can_manage_users: can_manage_users?,
        robots: response.headers["X-Robots-Tag"]
      }
    end

    def manage_users
      head :ok
    end

    def super_only
      head :ok
    end
  end

  before do
    routes.draw do
      get "anonymous" => "anonymous#index"
      get "manage_users" => "anonymous#manage_users"
      get "super_only" => "anonymous#super_only"
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
      json = JSON.parse(response.body)
      expect(json["admin"]).to be true
      expect(json["can_manage_users"]).to be true
    end

    it "identifies super_admin" do
      user.update_column(:role, "super_admin")
      get :index
      expect(JSON.parse(response.body)["super_admin"]).to be true
    end
  end

  describe "www redirect" do
    it "redirects www hosts to the canonical apex host in production" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      stub_const("ENV", ENV.to_hash.merge("APP_HOST" => "devdebizz.com", "APP_PROTOCOL" => "https"))
      request.host = "www.devdebizz.com"

      get :index

      expect(response).to redirect_to("https://devdebizz.com/anonymous")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "staging robots header" do
    it "sets X-Robots-Tag in staging" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("staging"))

      get :index

      expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
    end
  end

  describe "require_user_management_access!" do
    it "allows admins" do
      user.update!(role: "admin")
      get :manage_users
      expect(response).to have_http_status(:ok)
    end

    it "redirects employees" do
      user.update!(role: "employee")
      get :manage_users
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to include("manage users")
    end
  end

  describe "require_super_admin!" do
    it "allows super admins" do
      user.update_column(:role, "super_admin")
      get :super_only
      expect(response).to have_http_status(:ok)
    end

    it "redirects admins" do
      user.update!(role: "admin")
      get :super_only
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to include("permission")
    end
  end
end

RSpec.describe "Devise after sign in", type: :request do
  it "sends users to the admin root after login" do
    user = create(:user, :admin)

    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    expect(response).to redirect_to(admin_root_path)
  end
end
