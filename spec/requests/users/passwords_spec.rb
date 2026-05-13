require "rails_helper"

RSpec.describe "Users::Passwords", type: :request do
  let(:user) { create(:user, active: false) }

  describe "PUT /users/password" do
    it "activates the user on password update" do
      token = user.send_reset_password_instructions
      put user_password_path, params: {
        user: {
          reset_password_token: token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      }
      expect(user.reload.active).to be true
      expect(response).to redirect_to(admin_root_path)
    end
  end
end
