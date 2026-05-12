require 'rails_helper'

RSpec.describe SmsService do
  describe ".send_sms" do
    let(:to) { "+1234567890" }
    let(:message) { "Hello" }
    let(:twilio_client_mock) { double('TwilioClient') }
    let(:messages_mock) { double('Messages') }

    before do
      stub_const("TWILIO_CLIENT", twilio_client_mock)
      allow(twilio_client_mock).to receive(:messages).and_return(messages_mock)
    end

    it "calls the Twilio API" do
      expect(messages_mock).to receive(:create).with(
        from: ENV["TWILIO_PHONE_NUMBER"],
        to: to,
        body: message
      )
      SmsService.send_sms(to: to, message: message)
    end
  end
end
