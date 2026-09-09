# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::EmployeeAssignments", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:employee) { create(:user, role: "employee", name: "Insha Batool") }
  let(:other_employee) { create(:user, role: "employee", name: "Huma") }

  before { sign_in admin }

  describe "GET /admin/employees" do
    let!(:assigned) do
      create(
        :business,
        name: "Assigned Studio",
        sold_price: nil,
        subscription_fee: nil,
        subscription: false,
        assigned_to: employee,
        work_status: "assigned"
      )
    end
    let!(:unassigned) do
      create(:business, name: "Open Lead", sold_price: nil, subscription_fee: nil, subscription: false)
    end

    it "lists assigned businesses and omits unassigned ones" do
      assigned.update!(employee_report: "Called the owner, follow up Friday.")
      get admin_employees_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Employees")
      expect(response.body).to include("Employee report")
      expect(response.body).to include("Called the owner, follow up Friday.")
      expect(assigns(:businesses)).to include(assigned)
      expect(assigns(:businesses)).not_to include(unassigned)
    end

    it "escapes business names rather than rendering them as markup" do
      assigned.update!(name: "<script>alert(1)</script>Salon")

      get admin_employees_path

      expect(response.body).not_to include("<script>alert(1)</script>")
      expect(response.body).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
    end

    it "filters by employee tab" do
      other = create(
        :business,
        name: "Huma Lead",
        sold_price: nil,
        subscription_fee: nil,
        subscription: false,
        assigned_to: other_employee,
        work_status: "in_progress"
      )

      get admin_employees_path, params: { employee_id: employee.id }

      expect(assigns(:businesses)).to include(assigned)
      expect(assigns(:businesses)).not_to include(other)
      expect(response.body).to include("Insha Batool")
    end

    it "blocks employees" do
      sign_in create(:user, role: "employee")
      get admin_employees_path
      expect(response).to redirect_to(admin_root_path)
    end
  end
end
