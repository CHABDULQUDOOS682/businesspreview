# Preview all emails at http://localhost:3000/rails/mailers/contact_mailer
class ContactMailerPreview < ActionMailer::Preview
  def new_lead_alert
    ContactMailer.new_lead_alert(
      first_name: "Jane",
      last_name: "Doe",
      email: "jane.doe@example.com",
      company: "Innovate LLC",
      service_interest: "Web Design",
      message: "Hello, I am interested in your services. We would love to collaborate on our upcoming project."
    )
  end
end
