class CallService
  def self.call(to:)
    TWILIO_CLIENT.calls.create(
      from: ENV["TWILIO_PHONE_NUMBER"],
      to: to,
      url: "https://yourdomain.com/twilio/voice"
    )
  end
end