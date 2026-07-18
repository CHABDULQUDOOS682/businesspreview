# frozen_string_literal: true

class UnreadMessagesBroadcaster
  def self.broadcast!(business: nil)
    count = Message.inbound.unread.count

    %w[unread_messages_badge unread_messages_badge_mobile].each do |target|
      Turbo::StreamsChannel.broadcast_update_to(
        "unread_messages",
        target: target,
        partial: "admin/communications/unread_badge",
        locals: { count: count }
      )
    end

    Turbo::StreamsChannel.broadcast_update_to(
      "unread_messages",
      target: "unread_inbound_count",
      partial: "admin/dashboard/unread_inbound_count",
      locals: { count: count }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "unread_messages",
      target: "unread_indicator_source",
      partial: "admin/communications/unread_indicator_source",
      locals: { count: count }
    )

    Business.segment_unread_counts.each do |segment, unread|
      Turbo::StreamsChannel.broadcast_update_to(
        "unread_messages",
        target: "segment_unread_#{segment}",
        partial: "admin/shared/segment_unread_dot",
        locals: { unread: unread }
      )
    end

    return if business.blank?

    unread = business.messages.inbound.unread.count
    Turbo::StreamsChannel.broadcast_update_to(
      "unread_messages",
      target: ApplicationController.helpers.dom_id(business, :chat_unread),
      partial: "admin/shared/business_chat_unread",
      locals: { unread: unread }
    )
  end
end
