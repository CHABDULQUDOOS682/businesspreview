require "rails_helper"

RSpec.describe "Admin::CommissionRates", type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:admin) { create(:user, :admin) }
  let(:employee) { create(:user, role: "employee") }

  let!(:rate1) { create(:commission_rate, kind: "one_time", month_number: nil, percentage: 10.0) }
  let!(:rate2) { create(:commission_rate, kind: "subscription", month_number: 1, percentage: 8.0) }

  describe "GET /admin/commission_rates" do
    context "when super_admin" do
      before { sign_in super_admin }

      it "returns success and renders index" do
        get admin_commission_rates_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when admin" do
      before { sign_in admin }

      it "returns success and renders index" do
        get admin_commission_rates_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when employee" do
      before { sign_in employee }

      it "redirects to admin_root_path with alert" do
        get admin_commission_rates_path
        expect(response).to redirect_to(admin_root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when guest" do
      it "redirects to login" do
        get admin_commission_rates_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /admin/commission_rates/:id" do
    let(:params) do
      {
        commission_rates: {
          rate1.id => { percentage: 15.0 },
          rate2.id => { percentage: 12.0 }
        }
      }
    end

    context "when authorized (admin)" do
      before { sign_in admin }

      it "bulk updates percentages and redirects to index" do
        patch admin_commission_rate_path(rate1), params: params
        expect(response).to redirect_to(admin_commission_rates_path)
        expect(flash[:notice]).to be_present
        expect(rate1.reload.percentage).to eq(15.0)
        expect(rate2.reload.percentage).to eq(12.0)
      end

      it "rolls back and alerts on validation failure" do
        bad_params = {
          commission_rates: {
            rate1.id => { percentage: -5.0 } # invalid percentage
          }
        }
        patch admin_commission_rate_path(rate1), params: bad_params
        expect(response).to redirect_to(admin_commission_rates_path)
        expect(flash[:alert]).to be_present
        expect(rate1.reload.percentage).to eq(10.0) # untouched
      end
    end

    context "when unauthorized (employee)" do
      before { sign_in employee }

      it "does not update and redirects" do
        patch admin_commission_rate_path(rate1), params: params
        expect(response).to redirect_to(admin_root_path)
        expect(rate1.reload.percentage).to eq(10.0)
      end
    end
  end
end
