# Preview all emails at http://localhost:3000/rails/mailers/review_mailer
class ReviewMailerPreview < ActionMailer::Preview
  def send_link
    business = Business.new(
      name: "Acme Barber Shop",
      owner_name: "John Doe",
      email: "john.doe@example.com",
      review_token: "test_review_token"
    )
    ReviewMailer.send_link(business)
  end
end
