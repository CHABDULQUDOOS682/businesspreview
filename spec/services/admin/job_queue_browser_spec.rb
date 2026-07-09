# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/support/solid_queue")

RSpec.describe Admin::JobQueueBrowser, :solid_queue do
  subject(:browser) { described_class.new(filter: filter, queue_name: queue_name, class_name: class_name) }

  let(:filter) { "all" }
  let(:queue_name) { nil }
  let(:class_name) { nil }

  describe "#jobs and #stats" do
    before { SolidQueueTestHelper.enqueue_job(SubscriptionBillingJob) }

    it "returns all jobs by default" do
      expect(browser.jobs.count).to eq(1)
      expect(browser.stats[:all]).to eq(1)
      expect(browser.stats[:pending]).to eq(1)
    end

    %w[pending running scheduled blocked failed finished].each do |status|
      it "supports the #{status} filter" do
        filtered = described_class.new(filter: status)
        expect(filtered.jobs).to be_a(ActiveRecord::Relation)
      end
    end

    it "filters invalid status values back to all" do
      filtered = described_class.new(filter: "not-a-status")
      expect(filtered.filter).to eq("all")
    end

    it "filters by queue and class name" do
      job = SolidQueue::Job.last
      filtered = described_class.new(queue_name: job.queue_name, class_name: job.class_name)
      expect(filtered.jobs).to contain_exactly(job)
    end
  end

  describe "#worker_processes and #recurring_tasks" do
    before { SolidQueueTestHelper.enqueue_job(SubscriptionBillingJob) }

    it "returns collections" do
      expect(browser.worker_processes).to be_a(ActiveRecord::Relation)
      expect(browser.recurring_tasks).to be_a(ActiveRecord::Relation)
      expect(browser.queue_names).to include("default")
      expect(browser.class_names).to include("SubscriptionBillingJob")
    end
  end

  describe ".display_status" do
    let(:job) { SolidQueue::Job.last }

    before { SolidQueueTestHelper.enqueue_job(SubscriptionBillingJob) }

    it "returns pending for ready jobs" do
      expect(described_class.display_status(job)).to eq("pending")
    end

    it "returns finished for completed jobs" do
      job.update!(finished_at: Time.current)
      expect(described_class.display_status(job)).to eq("finished")
    end

    it "returns unknown when no status matches" do
      allow(job).to receive(:finished?).and_return(false)
      allow(job).to receive(:failed?).and_return(false)
      allow(job).to receive(:claimed?).and_return(false)
      allow(job).to receive(:blocked?).and_return(false)
      allow(job).to receive(:scheduled?).and_return(false)
      allow(job).to receive(:due?).and_return(false)
      allow(job).to receive(:ready?).and_return(false)

      expect(described_class.display_status(job)).to eq("unknown")
    end
  end

  describe ".arguments_summary" do
    before { SolidQueueTestHelper.enqueue_job(SubscriptionBillingJob) }

    let(:job) { SolidQueue::Job.last }

    it "returns a dash when arguments are missing" do
      allow(job).to receive(:arguments).and_return(nil)
      expect(described_class.arguments_summary(job)).to eq("—")
    end

    it "summarizes global id arguments" do
      business = create(:business)
      allow(job).to receive(:arguments).and_return(
        "arguments" => [ { "_aj_globalid" => business.to_global_id.to_s } ]
      )
      expect(described_class.arguments_summary(job)).to include("Business")
    end

    it "falls back when global id lookup fails" do
      allow(GlobalID::Locator).to receive(:locate).and_raise(StandardError, "missing")
      allow(job).to receive(:arguments).and_return(
        "arguments" => [ { "_aj_globalid" => "gid://preview-app/Business/1" } ]
      )

      expect(described_class.arguments_summary(job)).to include("gid://preview-app/Business/1")
    end

    it "summarizes plain hash arguments" do
      allow(job).to receive(:arguments).and_return("arguments" => [ { "foo" => "bar" } ])
      expect(described_class.arguments_summary(job)).to include("foo")
    end

    it "summarizes scalar arguments" do
      allow(job).to receive(:arguments).and_return("arguments" => [ "plain-arg" ])
      expect(described_class.arguments_summary(job)).to eq("plain-arg")
    end
  end
end
