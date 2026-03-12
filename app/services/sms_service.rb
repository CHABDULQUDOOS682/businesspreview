class SmsService
  def self.send_sms(to:, message:)
    TWILIO_CLIENT.messages.create(
      from: ENV["TWILIO_PHONE_NUMBER"],
      to: to,
      body: message
    )
  end
end
