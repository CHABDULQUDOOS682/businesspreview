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

  it "purges removed screenshots and attaches new ones" do
    feedback.screenshots.attach(
      io: StringIO.new("old"),
      filename: "old.png",
      content_type: "image/png"
    )
    old_id = feedback.screenshots.first.id
    new_upload = Rack::Test::UploadedFile.new(StringIO.new("new"), "image/png", true, original_filename: "new.png")

    updated = described_class.new(
      feedback: feedback,
      attributes: { admin_notes: "Updated screenshot" },
      screenshots: [ new_upload ],
      remove_screenshot_ids: [ old_id ]
    ).call

    expect(updated.screenshots.map(&:filename).map(&:to_s)).to include("new.png")
    expect(ActiveStorage::Attachment.exists?(old_id)).to be(false)
  end

  it "clears resolved_at when status moves away from a resolved state" do
    feedback.update!(status: "completed", resolved_at: 1.day.ago)

    updated = described_class.new(feedback: feedback, attributes: { status: "in_progress" }).call

    expect(updated.resolved_at).to be_nil
  end
end
