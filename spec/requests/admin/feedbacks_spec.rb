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

    it "filters feedback by search and attributes" do
      sign_in admin
      get admin_feedbacks_path, params: { q: "My feedback", status: "pending", feedback_type: "performance", priority: "medium", user_id: employee.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:feedbacks)).to include(my_feedback)
      expect(assigns(:feedbacks)).not_to include(other_feedback)
    end
  end

  describe "GET /admin/feedbacks/new" do
    it "prefills the page url when provided" do
      sign_in employee
      get new_admin_feedback_path(page_url: "https://example.com/admin/businesses")

      expect(response).to have_http_status(:ok)
      expect(assigns(:feedback).page_url).to eq("https://example.com/admin/businesses")
    end
  end

  describe "GET /admin/feedbacks/:id" do
    it "allows employees to view their own feedback" do
      sign_in employee
      get admin_feedback_path(my_feedback)

      expect(response).to have_http_status(:ok)
    end

    it "blocks employees from viewing another user's feedback" do
      sign_in employee
      get admin_feedback_path(other_feedback)

      expect(response).to redirect_to(admin_feedbacks_path)
      expect(flash[:alert]).to include("do not have access")
    end

    it "returns not found for missing feedback" do
      sign_in admin
      get admin_feedback_path(id: 999_999)

      expect(response).to redirect_to(admin_feedbacks_path)
      expect(flash[:alert]).to eq("Feedback not found.")
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

    it "renders the form again when validation fails" do
      sign_in employee

      post admin_feedbacks_path, params: {
        feedback: { title: "", description: "", feedback_type: "general" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Submit Feedback")
    end
  end

  describe "GET /admin/feedbacks/:id/edit" do
    it "allows employees to edit pending feedback" do
      sign_in employee
      get edit_admin_feedback_path(my_feedback)

      expect(response).to have_http_status(:ok)
    end

    it "redirects when the employee cannot edit the feedback" do
      my_feedback.update!(status: "under_review")
      sign_in employee

      get edit_admin_feedback_path(my_feedback)

      expect(response).to redirect_to(admin_feedback_path(my_feedback))
      expect(flash[:alert]).to include("cannot edit")
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

    it "lets employees update their pending feedback" do
      sign_in employee

      patch admin_feedback_path(my_feedback), params: {
        feedback: { title: "Updated title", description: "Updated description", feedback_type: "general" }
      }

      expect(response).to redirect_to(admin_feedback_path(my_feedback))
      expect(my_feedback.reload.title).to eq("Updated title")
    end

    it "lets super admins update all fields" do
      sign_in super_admin

      patch admin_feedback_path(my_feedback), params: {
        feedback: {
          title: "Super updated",
          description: "Super description",
          feedback_type: "improvement",
          priority: "high",
          status: "planned",
          admin_notes: "Prioritized"
        }
      }

      expect(my_feedback.reload).to have_attributes(
        title: "Super updated",
        priority: "high",
        status: "planned",
        admin_notes: "Prioritized"
      )
    end

    it "renders edit when validation fails" do
      sign_in admin

      patch admin_feedback_path(my_feedback), params: { feedback: { status: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /admin/feedbacks/:id/resolve" do
    it "marks feedback completed for super admins" do
      sign_in super_admin

      patch resolve_admin_feedback_path(my_feedback)

      expect(response).to redirect_to(admin_feedback_path(my_feedback))
      expect(my_feedback.reload).to be_completed
    end

    it "blocks non-super admins" do
      sign_in admin

      patch resolve_admin_feedback_path(my_feedback)

      expect(response).to redirect_to(admin_feedback_path(my_feedback))
      expect(flash[:alert]).to include("Only super admins")
    end

    it "redirects with an alert when resolve fails validation" do
      sign_in super_admin
      service = instance_double(FeedbackUpdateService)
      allow(FeedbackUpdateService).to receive(:new) do |feedback:, **|
        feedback.errors.add(:base, "invalid")
        allow(service).to receive(:call).and_raise(ActiveRecord::RecordInvalid.new(feedback))
        service
      end

      patch resolve_admin_feedback_path(my_feedback)

      expect(response).to redirect_to(admin_feedback_path(my_feedback))
      expect(flash[:alert]).to eq("invalid")
    end
  end

  describe "PATCH /admin/feedbacks/:id/close" do
    it "marks feedback closed for super admins" do
      sign_in super_admin

      patch close_admin_feedback_path(my_feedback)

      expect(response).to redirect_to(admin_feedback_path(my_feedback))
      expect(my_feedback.reload).to be_closed
    end

    it "redirects with an alert when close fails validation" do
      sign_in super_admin
      service = instance_double(FeedbackUpdateService)
      allow(FeedbackUpdateService).to receive(:new) do |feedback:, **|
        feedback.errors.add(:base, "invalid")
        allow(service).to receive(:call).and_raise(ActiveRecord::RecordInvalid.new(feedback))
        service
      end

      patch close_admin_feedback_path(my_feedback)

      expect(response).to redirect_to(admin_feedback_path(my_feedback))
      expect(flash[:alert]).to eq("invalid")
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
