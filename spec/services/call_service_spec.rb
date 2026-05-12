require 'rails_helper'

RSpec.describe CallService do
  describe ".call" do
    let(:to) { "+1234567890" }
    let(:twilio_client_mock) { double('TwilioClient') }
    let(:calls_mock) { double('Calls') }

    before do
      stub_const("TWILIO_CLIENT", twilio_client_mock)
      allow(twilio_client_mock).to receive(:calls).and_return(calls_mock)
    end

    it "calls the Twilio API" do
      expect(calls_mock).to receive(:create).with(
        from: ENV["TWILIO_PHONE_NUMBER"],
        to: to,
        url: kind_of(String)
      )
      CallService.call(to: to)
    end
  end
end
