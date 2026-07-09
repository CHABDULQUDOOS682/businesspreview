require "rails_helper"

RSpec.describe FeedbackUpdateService do
  include ActiveJob::TestHelper

  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    example.run
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  let(:user) { create(:user, role: "employee") }
  let(:feedback) { create(:feedback, user: user, status: "pending") }

  it "notifies the creator when status changes" do
    expect {
      described_class.new(feedback: feedback, attributes: { status: "under_review" }).call
    }.to have_enqueued_mail(FeedbackMailer, :status_changed).with(feedback)
  end

  it "sets resolved_at when status becomes completed" do
    updated = described_class.new(feedback: feedback, attributes: { status: "completed" }).call
    expect(updated.resolved_at).to be_present
  end

  it "does not notify when status is unchanged" do
    expect {
      described_class.new(feedback: feedback, attributes: { admin_notes: "Looking into this" }).call
    }.not_to have_enqueued_mail(FeedbackMailer, :status_changed)
  end
end
