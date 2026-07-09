class FeedbackMailer < ApplicationMailer
  def status_changed(feedback)
    @feedback = feedback
    mail(
      to: feedback.user.email,
      subject: "Feedback update: #{feedback.title}"
    )
  end
end
