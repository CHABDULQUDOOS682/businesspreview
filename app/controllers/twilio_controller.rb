class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :voice, :sms, :connect_call, :dial_status ]
  skip_before_action :authenticate_user!, only: [ :voice, :sms, :connect_call, :dial_status ]
  skip_before_action :set_unread_message_count, only: [ :voice, :sms, :connect_call, :dial_status ]

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

  # --- Browser calling ---

  # Generates an Access Token with Voice grant for the Twilio Voice JS SDK
  def access_token
    unless ENV["TWILIO_API_KEY"].present? && ENV["TWILIO_API_SECRET"].present? && ENV["TWILIO_TWIML_APP_SID"].present?
      render json: { error: "Missing Twilio API Key, Secret, or TwiML App SID in .env" }, status: :unprocessable_entity
      return
    end

    identity = "user-#{current_user.id}"
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

    to_number = params[:number].presence || params[:To].presence
    user = find_caller_user
    business = find_business_from_params(to_number)

    if to_number.present?
      CallLogRecorder.record_outbound!(
        user: user,
        business: business,
        to_number: to_number,
        from_number: ENV["TWILIO_PHONE_NUMBER"],
        twilio_call_sid: params[:CallSid],
        status: "initiated"
      )

      response.dial(
        caller_id: ENV["TWILIO_PHONE_NUMBER"],
        action: dial_status_url,
        method: "POST"
      ) do |dial|
        dial.number(to_number)
      end
    else
      response.say(message: "Error: No number provided to call.")
    end

    render xml: response.to_s
  end

  # Dial action callback — update duration/status when the dialed leg finishes
  def dial_status
    call_log = CallLog.find_by(twilio_call_sid: params[:CallSid])
    if call_log
      call_log.update(
        status: params[:DialCallStatus].presence || params[:CallStatus].presence || call_log.status,
        duration_seconds: params[:DialCallDuration].presence&.to_i || call_log.duration_seconds
      )
    end

    head :ok
  end

  private

  def find_caller_user
    if params[:UserId].present?
      User.find_by(id: params[:UserId])
    elsif params[:Caller].to_s.start_with?("client:user-")
      User.find_by(id: params[:Caller].to_s.delete_prefix("client:user-"))
    end
  end

  def find_business_from_params(to_number)
    if params[:BusinessId].present?
      Business.find_by(id: params[:BusinessId])
    else
      CallLogRecorder.find_business_for_phone(to_number)
    end
  end

  def dial_status_url
    "#{request.base_url}/twilio/dial_status"
  end
end
