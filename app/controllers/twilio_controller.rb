class TwilioController < ApplicationController
  skip_before_action :verify_authenticity_token

  def voice
    response = Twilio::TwiML::VoiceResponse.new

    response.say(
      message: "Hello, this is Abdul. I created a free website preview for your barber shop. Please check the SMS I sent you.",
      voice: "alice"
    )

    render xml: response.to_s
  end
end