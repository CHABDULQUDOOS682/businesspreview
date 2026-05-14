class ReviewMailer < ApplicationMailer
  def send_link(business)
    @business = business
    @link = business.review_url
    mail(to: @business.email, subject: "We'd love your feedback - #{@business.name}")
  end
end
