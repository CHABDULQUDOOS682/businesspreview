require "rails_helper"

RSpec.describe "Admin::Commissions", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:employee) { create(:user, role: "employee") }
  let(:other_employee) { create(:user, role: "employee") }
  let(:business) { create(:business, sold_by: employee) }
  let(:invoice) { create(:payment_invoice, business: business, status: "paid", paid_at: Time.current, amount_cents: 50000) }

  let!(:commission) do
    create(
      :commission,
      business: business,
      user: employee,
      payment_invoice: invoice,
      base_amount: 500,
      percentage: 10,
      commission_amount: 50,
      status: "pending"
    )
  end

  describe "GET /admin/commissions" do
    it "allows admins to see employee commission details" do
      sign_in admin

      get admin_commissions_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Commission by Employee")
      expect(response.body).to include(employee.email)
      expect(response.body).to include(business.name)
      expect(response.body).to include("$50.00")
    end

    it "shows per-employee totals and filters details by employee" do
      other_business = create(:business, sold_by: other_employee, name: "Other Deal")
      other_invoice = create(:payment_invoice, business: other_business, status: "paid", paid_at: Time.current, amount_cents: 70000)
      create(
        :commission,
        business: other_business,
        user: other_employee,
        payment_invoice: other_invoice,
        base_amount: 700,
        percentage: 10,
        commission_amount: 70
      )

      sign_in admin
      get admin_commissions_path, params: { employee_id: other_employee.id }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Commission by Employee")
      expect(response.body).to include(other_employee.email)
      expect(response.body).to include("$70.00")
      expect(response.body).to include("Other Deal")
      expect(response.body).not_to include(business.name)
    end

    it "limits employees to their own commissions" do
      other_business = create(:business, sold_by: other_employee, name: "Other Deal")
      other_invoice = create(:payment_invoice, business: other_business, status: "paid", paid_at: Time.current)
      create(:commission, business: other_business, user: other_employee, payment_invoice: other_invoice)

      sign_in employee
      get admin_commissions_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(business.name)
      expect(response.body).not_to include("Other Deal")
    end
  end

  describe "PATCH /admin/commissions/:id/approve" do
    it "approves pending commissions and can update the locked rate" do
      sign_in admin

      patch approve_admin_commission_path(commission), params: { percentage: 12 }

      expect(response).to redirect_to(admin_commissions_path)
      expect(commission.reload.status).to eq("approved")
      expect(commission.percentage).to eq(12)
      expect(commission.commission_amount).to eq(60)
    end

    it "does not allow employees to approve commissions" do
      sign_in employee

      patch approve_admin_commission_path(commission), params: { percentage: 12 }

      expect(response).to redirect_to(admin_commissions_path)
      expect(commission.reload.status).to eq("pending")
    end
  end

  describe "PATCH /admin/commissions/:id/mark_paid_out" do
    it "marks approved commissions as paid out" do
      commission.approve!(admin)
      sign_in admin

      patch mark_paid_out_admin_commission_path(commission)

      expect(response).to redirect_to(admin_commissions_path)
      expect(commission.reload.status).to eq("paid_out")
      expect(commission.paid_out_at).to be_present
    end
  end
end
