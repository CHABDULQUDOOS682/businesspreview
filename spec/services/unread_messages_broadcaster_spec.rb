# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnreadMessagesBroadcaster do
  let!(:business) { create(:business, phone: "+15551234567") }

  it "broadcasts unread badge targets, segment dots, and the business chat unread" do
    expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
      "unread_messages",
      hash_including(target: "unread_messages_badge")
    )
    expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
      "unread_messages",
      hash_including(target: "unread_messages_badge_mobile")
    )
    expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
      "unread_messages",
      hash_including(target: "unread_inbound_count")
    )
    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
      "unread_messages",
      hash_including(target: "unread_indicator_source")
    )
    Business::SEGMENTS.keys.each do |segment|
      expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
        "unread_messages",
        hash_including(target: "segment_unread_#{segment}")
      )
    end
    expect(Turbo::StreamsChannel).to receive(:broadcast_update_to).with(
      "unread_messages",
      hash_including(target: ApplicationController.helpers.dom_id(business, :chat_unread))
    )

    described_class.broadcast!(business: business)
  end
end
