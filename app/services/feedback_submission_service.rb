class FeedbackSubmissionService
  def initialize(user:, attributes:, screenshots: [])
    @user = user
    @attributes = attributes
    @screenshots = Array(screenshots).compact_blank
  end

  def call
    feedback = @user.feedbacks.build(@attributes)
    feedback.priority = "medium"
    feedback.status = "pending"
    feedback.screenshots.attach(@screenshots) if @screenshots.any?

    feedback.tap(&:save!)
  end
end
