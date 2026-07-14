require "rails_helper"

RSpec.describe "Admin::AvailabilityRules", type: :request do
  let!(:super_admin) { create(:user, :super_admin) }
  let(:admin) { create(:user, :admin) }
  let(:employee) { create(:user, role: "employee") }

  describe "unauthenticated access" do
    it "redirects GET /admin/availability_rules/edit to login" do
      get edit_admin_availability_rules_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects PUT /admin/availability_rules to login" do
      put admin_availability_rules_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "employee access" do
    before { sign_in employee }

    it "redirects edit away from employees" do
      get edit_admin_availability_rules_path
      expect(response).to redirect_to(admin_root_path)
    end

    it "redirects update away from employees" do
      put admin_availability_rules_path, params: {
        days: { "1": { enabled: "1", start_time: "09:00", end_time: "17:00" } }
      }
      expect(response).to redirect_to(admin_root_path)
      expect(super_admin.availability_rules.count).to eq(0)
    end
  end

  describe "admin access" do
    before { sign_in admin }

    it "renders the edit page successfully" do
      get edit_admin_availability_rules_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(super_admin.email)
    end

    it "updates the scheduling owner availability rules" do
      expect {
        put admin_availability_rules_path, params: {
          days: {
            "1": { enabled: "1", start_time: "09:00", end_time: "17:00" },
            "2": { enabled: "1", start_time: "10:00", end_time: "16:00" },
            "3": { enabled: "0", start_time: "09:00", end_time: "17:00" }
          }
        }
      }.to change(super_admin.availability_rules, :count).by(2)

      expect(response).to redirect_to(edit_admin_availability_rules_path)
      expect(flash[:notice]).to eq("Company availability updated.")

      rules = super_admin.availability_rules.order(:day_of_week)
      expect(rules[0].day_of_week).to eq(1)
      expect(rules[0].start_minute).to eq(540)
      expect(rules[0].end_minute).to eq(1020)
      expect(rules[1].day_of_week).to eq(2)
      expect(rules[1].start_minute).to eq(600)
      expect(rules[1].end_minute).to eq(960)
    end

    it "handles validation errors gracefully" do
      put admin_availability_rules_path, params: {
        days: {
          "1": { enabled: "1", start_time: "10:00", end_time: "09:00" }
        }
      }

      expect(response).to redirect_to(edit_admin_availability_rules_path)
      expect(flash[:alert]).to include("must be after start time")
    end

    it "redirects when no scheduling owner is configured" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SCHEDULING_OWNER_EMAIL").and_return("missing-owner@example.com")
      super_admin.destroy!

      get edit_admin_availability_rules_path

      expect(response).to redirect_to(admin_root_path)
      expect(flash[:alert]).to include("No scheduling owner")
    end
  end
end
