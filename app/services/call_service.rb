class CallService
  def self.call(to:, voice_url: nil)
    # Use provided voice_url, or fallback to ENV, or default to a dummy if none
    url = voice_url || ENV["TWILIO_VOICE_URL"] || "https://chieko-hydrazo-thurman.ngrok-free.dev/twilio/voice"

    TWILIO_CLIENT.calls.create(
      from: ENV["TWILIO_PHONE_NUMBER"],
      to: to,
      url: url
    )
  end
end
