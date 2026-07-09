# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/support/solid_queue")

RSpec.describe "Admin::Jobs", type: :request, solid_queue: true do
  let(:super_admin) { create(:user, :super_admin) }

  before { sign_in super_admin }

  describe "GET /admin/jobs" do
    it "lists enqueued jobs" do
      SolidQueueTestHelper.enqueue_job(SubscriptionBillingJob)

      get admin_jobs_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("SubscriptionBillingJob")
      expect(response.body).to include("Pending")
    end

    it "filters by status" do
      get admin_jobs_path(status: "finished")

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /admin/jobs/:id" do
    it "shows job details" do
      SolidQueueTestHelper.enqueue_job(SubscriptionBillingJob)
      job = SolidQueue::Job.last

      get admin_job_path(job)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("SubscriptionBillingJob")
      expect(response.body).to include("Arguments")
    end
  end

  describe "authorization" do
    it "redirects employees" do
      sign_in create(:user, role: "employee")

      get admin_jobs_path

      expect(response).to redirect_to(admin_root_path)
    end
  end
end
