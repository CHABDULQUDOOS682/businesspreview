class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def voice
    response = Twilio::TwiML::VoiceResponse.new

    response.say(
      message: "Hello, this is Abdul. I created a free website preview for your barber shop. Please check the SMS I sent you.",
      voice: "alice"
    )

    render xml: response.to_s
  end

  def sms
    # Webhook to receive incoming SMS
    from_number = params[:From].to_s.strip
    body = params[:Body].to_s.strip
    to_number = params[:To].to_s.strip

    # Try to find a business with this phone number
    # Remove leading + and country codes for matching if necessary
    # Check for the last 10 digits to match (common format)
    business = Business.find_by(phone: from_number) ||
               Business.find_by("phone LIKE ?", "%#{from_number.last(10)}") if from_number.present?

    Message.create!(
      from_number: from_number,
      to_number: to_number,
      body: body,
      direction: "inbound",
      business: business
    )



    response = Twilio::TwiML::MessagingResponse.new
    # response.message(body: "Thank you for your message! We'll get back to you soon.")

    render xml: response.to_s
  end

  # --- NEW BROWSER CALLING METHODS ---

  # Generates an Access Token with Voice grant for the Twilio Voice JS SDK
  def access_token
    # Require API Key/Secret for Voice SDK
    unless ENV["TWILIO_API_KEY"].present? && ENV["TWILIO_API_SECRET"].present? && ENV["TWILIO_TWIML_APP_SID"].present?
      render json: { error: "Missing Twilio API Key, Secret, or TwiML App SID in .env" }, status: :unprocessable_entity
      return
    end

    identity = "admin-browser-user"
    grant = Twilio::JWT::AccessToken::VoiceGrant.new
    grant.outgoing_application_sid = ENV["TWILIO_TWIML_APP_SID"]
    grant.incoming_allow = true

    token = Twilio::JWT::AccessToken.new(
      ENV["TWILIO_ACCOUNT_SID"],
      ENV["TWILIO_API_KEY"],
      ENV["TWILIO_API_SECRET"],
      [ grant ],
      identity: identity,
      ttl: 3600
    )

    render json: { token: token.to_jwt, identity: identity }
  end

  # TwiML callback for the TwiML App when a browser initiates a call
  def connect_call
    response = Twilio::TwiML::VoiceResponse.new

    # The browser sends the phone number to call in the 'number' parameter
    to_number = params[:number] || params[:To]

    if to_number.present?
      response.dial(caller_id: ENV["TWILIO_PHONE_NUMBER"]) do |dial|
        dial.number(to_number)
      end
    else
      response.say(message: "Error: No number provided to call.")
    end

    render xml: response.to_s
  end
end
