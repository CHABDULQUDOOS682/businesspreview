require "rails_helper"

RSpec.describe "Admin::Feedbacks", type: :request do
  let(:employee) { create(:user, role: "employee") }
  let(:other_employee) { create(:user, role: "employee") }
  let(:admin) { create(:user, :admin) }
  let(:super_admin) { create(:user, :super_admin) }
  let!(:my_feedback) { create(:feedback, user: employee, title: "My feedback item") }
  let!(:other_feedback) { create(:feedback, user: other_employee, title: "Other feedback item") }

  describe "GET /admin/feedbacks" do
    it "shows only the employee's feedback" do
      sign_in employee
      get admin_feedbacks_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My feedback item")
      expect(response.body).not_to include("Other feedback item")
      expect(response.body).to include("Total")
    end

    it "shows all feedback for admins" do
      sign_in admin
      get admin_feedbacks_path

      expect(response.body).to include("My feedback item")
      expect(response.body).to include("Other feedback item")
    end
  end

  describe "POST /admin/feedbacks" do
    it "creates feedback for the current user" do
      sign_in employee

      expect {
        post admin_feedbacks_path, params: {
          feedback: {
            title: "Broken filter",
            description: "Business filter does not reset",
            feedback_type: "bug",
            steps_to_reproduce: "Open page",
            expected_result: "Reset works",
            actual_result: "Reset fails"
          }
        }
      }.to change(Feedback, :count).by(1)

      expect(response).to redirect_to(admin_feedback_path(Feedback.last))
      expect(Feedback.last).to have_attributes(user: employee, priority: "medium", status: "pending")
    end
  end

  describe "PATCH /admin/feedbacks/:id" do
    it "lets admins update triage fields" do
      sign_in admin

      patch admin_feedback_path(my_feedback), params: {
        feedback: { status: "under_review", priority: "high", admin_notes: "Investigating" }
      }

      expect(my_feedback.reload).to have_attributes(status: "under_review", priority: "high", admin_notes: "Investigating")
    end

    it "prevents employees from editing non-pending feedback" do
      my_feedback.update!(status: "under_review")
      sign_in employee

      patch admin_feedback_path(my_feedback), params: {
        feedback: { title: "Changed title" }
      }

      expect(response).to redirect_to(admin_feedback_path(my_feedback))
      expect(my_feedback.reload.title).to eq("My feedback item")
    end
  end

  describe "DELETE /admin/feedbacks/:id" do
    it "allows super admins to delete feedback" do
      sign_in super_admin

      expect {
        delete admin_feedback_path(my_feedback)
      }.to change(Feedback, :count).by(-1)
    end

    it "blocks admins from deleting feedback" do
      sign_in admin

      delete admin_feedback_path(my_feedback)

      expect(response).to redirect_to(admin_feedbacks_path)
      expect(Feedback.exists?(my_feedback.id)).to be(true)
    end
  end
end
