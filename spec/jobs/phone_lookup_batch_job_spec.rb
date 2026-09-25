# frozen_string_literal: true

require "rails_helper"

RSpec.describe PhoneLookupBatchJob, type: :job do
  include ActiveJob::TestHelper

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  let!(:unchecked) { create(:business, phone: "+15551110001", phone_lookup_checked_at: nil) }
  let!(:checked) do
    create(:business, phone: "+15551110002", phone_lookup_checked_at: 1.day.ago, phone_line_type: "mobile")
  end

  it "queues lookups only for unchecked businesses by default" do
    expect {
      described_class.perform_now
    }.to have_enqueued_job(PhoneLookupJob).with(unchecked.id)

    expect(PhoneLookupJob).not_to have_been_enqueued.with(checked.id)
  end

  it "queues lookups for all businesses when only_unchecked is false" do
    expect {
      described_class.perform_now(only_unchecked: false)
    }.to have_enqueued_job(PhoneLookupJob).with(unchecked.id)
      .and have_enqueued_job(PhoneLookupJob).with(checked.id)
  end
end
