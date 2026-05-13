require "rails_helper"

RSpec.describe Message, type: :model do
  let(:business) { create(:business, phone: "+1234567890") }

  describe "callbacks" do
    it "sets read_at for outbound messages" do
      msg = create(:message, direction: "outbound")
      expect(msg.read_at).to be_present
    end

    it "does not set read_at for inbound messages" do
      msg = create(:message, direction: "inbound")
      expect(msg.read_at).to be_nil
    end

    it "normalizes numbers before save" do
      msg = create(:message, from_number: " +1 234 567 890 ")
      expect(msg.from_number).to eq("+1234567890")
    end

    it "broadcasts updates after create" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).at_least(:once)
      create(:message, direction: "inbound", from_number: "+1234567890", business: business)
    end
  end

  describe "scopes" do
    it "filters inbound and outbound" do
      create(:message, direction: "inbound")
      create(:message, direction: "outbound")
      expect(Message.inbound.count).to eq(1)
      expect(Message.outbound.count).to eq(1)
    end

    it "filters unread messages" do
      create(:message, direction: "inbound", read_at: nil)
      create(:message, direction: "inbound", read_at: Time.current)
      expect(Message.unread.count).to eq(1)
    end
  end
end
