class ContactMailer < ApplicationMailer

  def new_lead_alert(params)
    @first_name       = params[:first_name]
    @last_name        = params[:last_name]
    @email            = params[:email]
    @company          = params[:company]
    @service_interest = params[:service_interest]
    @message          = params[:message]

    mail(
      to: "developer.qudoos@gmail.com",
      subject: "🔥 New Lead Inbound: #{@first_name} #{@last_name} - #{@service_interest}"
    )
  end
end
