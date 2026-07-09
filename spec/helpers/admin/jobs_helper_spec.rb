# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::JobsHelper, type: :helper do
  describe "#admin_job_status_badge" do
    it "renders each status" do
      job = instance_double(SolidQueue::Job)
      %w[pending running scheduled blocked failed finished unknown].each do |status|
        allow(Admin::JobQueueBrowser).to receive(:display_status).with(job).and_return(status)
        html = helper.admin_job_status_badge(job)
        expect(html).to include(Admin::JobsHelper::STATUS_LABELS.fetch(status, status.humanize))
      end
    end
  end

  describe "#admin_job_filter_link" do
    let(:browser) { Admin::JobQueueBrowser.new(filter: "all") }

    it "renders an active filter link" do
      html = helper.admin_job_filter_link("All", "all", browser)
      expect(html).to include("All")
      expect(html).to include(browser.stats[:all].to_s)
    end
  end

  describe "#admin_job_arguments" do
    it "renders json for hash arguments" do
      job = instance_double(SolidQueue::Job, arguments: { "job_class" => "TestJob" })
      expect(helper.admin_job_arguments(job)).to include("TestJob")
    end

    it "renders a dash for missing arguments" do
      job = instance_double(SolidQueue::Job, arguments: nil)
      expect(helper.admin_job_arguments(job)).to include("—")
    end
  end

  describe "#admin_job_error" do
    it "renders failed execution details" do
      execution = instance_double(
        SolidQueue::FailedExecution,
        exception_class: "RuntimeError",
        message: "boom",
        backtrace: [ "line 1" ]
      )
      job = instance_double(SolidQueue::Job, failed_execution: execution)

      expect(helper.admin_job_error(job)).to include("RuntimeError: boom")
    end

    it "returns nil when there is no failed execution" do
      job = instance_double(SolidQueue::Job, failed_execution: nil)
      expect(helper.admin_job_error(job)).to be_nil
    end
  end
end
