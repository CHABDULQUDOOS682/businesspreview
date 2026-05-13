require 'rails_helper'

RSpec.describe "Admin::Users", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:admin) { create(:user, :admin) }
  let(:employee) { create(:user) }

  before do
    sign_in super_admin
  end

  describe "GET /admin/users" do
    it "returns http success" do
      get admin_users_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/users/new" do
    it "returns http success" do
      get new_admin_user_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/users" do
    let(:valid_params) do
      {
        user: {
          email: "newuser@example.com",
          role: "employee"
        }
      }
    end

    it "creates a new user and redirects" do
      expect {
        post admin_users_path, params: valid_params
      }.to change(User, :count).by(1)
      expect(response).to redirect_to(admin_users_path)
    end

    it "uses fallback role if invalid role is provided" do
      post admin_users_path, params: { user: { email: "fallback@example.com", role: "super_admin" } }
      expect(User.last.role).to eq("admin")
    end

    it "renders new if creation fails" do
      post admin_users_path, params: { user: { email: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/users/:id/toggle_status" do
    it "toggles the user active status and redirects" do
      patch toggle_status_admin_user_path(employee)
      expect(employee.reload.active).to be false
      expect(response).to redirect_to(admin_users_path)
    end

    it "denies permission if cannot manage" do
      sign_out super_admin
      sign_in admin
      other_admin = create(:user, :admin)
      patch toggle_status_admin_user_path(other_admin)
      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to include("permission")
    end
  end

  describe "POST /admin/users/:id/resend_invite" do
    before { employee.update(active: false) }

    it "sends reset password instructions and redirects" do
      expect_any_instance_of(User).to receive(:send_reset_password_instructions)
      post resend_invite_admin_user_path(employee)
      expect(response).to redirect_to(admin_users_path)
    end

    it "denies permission if cannot manage" do
      sign_out super_admin
      sign_in admin
      other_admin = create(:user, :admin)
      post resend_invite_admin_user_path(other_admin)
      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to include("permission")
    end

    it "fails if user is already active" do
      employee.update(active: true)
      post resend_invite_admin_user_path(employee)
      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to include("Only inactive")
    end
  end

  describe "DELETE /admin/users/:id" do
    it "destroys the user and redirects" do
      user_to_delete = create(:user)
      expect {
        delete admin_user_path(user_to_delete)
      }.to change(User, :count).by(-1)
      expect(response).to redirect_to(admin_users_path)
    end

    it "denies permission if cannot manage" do
      sign_out super_admin
      sign_in admin
      other_admin = create(:user, :admin)
      delete admin_user_path(other_admin)
      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to include("permission")
    end
  end

  context "when signed in as admin" do
    before do
      sign_out super_admin
      sign_in admin
    end

    it "returns manageable users" do
      get admin_users_path
      expect(response).to have_http_status(:success)
    end

    it "creates user with fallback to first allowed role when role is super_admin" do
      post admin_users_path, params: { user: { email: "newadmin@example.com", role: "super_admin" } }
      expect(User.find_by(email: "newadmin@example.com").role).to eq("employee")
    end
  end

  context "when signed in as employee" do
    before do
      sign_out super_admin
      sign_in employee
    end

    it "redirects to admin root with alert" do
      get admin_users_path
      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to be_present
    end
  end

  context "when employee bypasses guard (manageable_users returns User.none)" do
    it "returns User.none for an employee role via direct model method" do
      # Direct unit test to cover the User.none branch (line 75 of users_controller)
      # which is unreachable via normal requests because `require_user_management_access!`
      # redirects employees before the index action runs.
      controller_instance = Admin::UsersController.new
      allow(controller_instance).to receive(:current_user).and_return(employee)
      result = controller_instance.send(:manageable_users)
      expect(result).to eq(User.none)
    end
  end
end
