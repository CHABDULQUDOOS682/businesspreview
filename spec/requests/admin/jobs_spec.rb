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

    it "filters by queue and class name" do
      SolidQueueTestHelper.enqueue_job(SubscriptionBillingJob)

      get admin_jobs_path(queue_name: "default", class_name: "SubscriptionBillingJob")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("SubscriptionBillingJob")
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

  describe "POST /admin/jobs/:id/retry" do
    it "retries a failed job" do
      SolidQueueTestHelper.enqueue_job(SubscriptionBillingJob)
      job = SolidQueue::Job.includes(:failed_execution).last
      job.failed_with(RuntimeError.new("boom"))

      post retry_admin_job_path(job)

      expect(response).to redirect_to(admin_job_path(job))
      expect(flash[:notice]).to include("queued for retry")
    end

    it "redirects when the job is not failed" do
      SolidQueueTestHelper.enqueue_job(SubscriptionBillingJob)
      job = SolidQueue::Job.last

      post retry_admin_job_path(job)

      expect(response).to redirect_to(admin_job_path(job))
      expect(flash[:alert]).to include("Only failed jobs can be retried")
    end
  end

  describe "POST /admin/jobs/enqueue_phone_lookup" do
    include ActiveJob::TestHelper

    around do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      clear_enqueued_jobs
      example.run
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
    end

    it "queues PhoneLookupBatchJob for unchecked businesses" do
      expect {
        post enqueue_phone_lookup_admin_jobs_path, params: { only_unchecked: true }
      }.to have_enqueued_job(PhoneLookupBatchJob).with(only_unchecked: true)

      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:notice]).to include("unchecked")
    end

    it "queues PhoneLookupBatchJob for all businesses when only_unchecked is false" do
      expect {
        post enqueue_phone_lookup_admin_jobs_path, params: { only_unchecked: false }
      }.to have_enqueued_job(PhoneLookupBatchJob).with(only_unchecked: false)

      expect(response).to redirect_to(admin_jobs_path)
      expect(flash[:notice]).to include("all businesses")
    end

    it "shows the verify buttons on the index for super admins" do
      create(:business, phone: "+15551112222", phone_lookup_checked_at: nil)

      get admin_jobs_path

      expect(response.body).to include("Verify unchecked phones")
      expect(response.body).to include("Re-verify all phones")
    end

    it "denies admins from enqueueing" do
      sign_in create(:user, :admin)

      expect {
        post enqueue_phone_lookup_admin_jobs_path
      }.not_to have_enqueued_job(PhoneLookupBatchJob)

      expect(response).to redirect_to(admin_root_path)
    end
  end

  describe "authorization" do
    it "allows admins" do
      sign_in create(:user, :admin)

      get admin_jobs_path

      expect(response).to have_http_status(:ok)
    end

    it "hides phone verify buttons from admins" do
      sign_in create(:user, :admin)

      get admin_jobs_path

      expect(response.body).not_to include("Verify unchecked phones")
      expect(response.body).not_to include("Re-verify all phones")
    end

    it "redirects employees" do
      sign_in create(:user, role: "employee")

      get admin_jobs_path

      expect(response).to redirect_to(admin_root_path)
    end
  end
end
