class Message < ApplicationRecord
  belongs_to :business, optional: true

  validates :from_number, presence: true
  validates :to_number, presence: true
  validates :body, presence: true
  validates :direction, inclusion: { in: %w[inbound outbound] }

  before_save :normalize_numbers
  before_validation :set_default_read_at, on: :create

  after_create_commit :broadcast_realtime_updates

  scope :inbound, -> { where(direction: "inbound") }
  scope :outbound, -> { where(direction: "outbound") }
  scope :unread, -> { where(read_at: nil) }

  private

  def set_default_read_at
    self.read_at ||= Time.current if direction == "outbound"
  end

  def broadcast_realtime_updates
    key = conversation_key
    return if key.blank?

    broadcast_append_to(
      "conversation:#{key}",
      target: "message_list",
      partial: "admin/communications/message",
      locals: { msg: self }
    )

    if direction == "inbound"
      Turbo::StreamsChannel.broadcast_update_to(
        "unread_messages",
        target: "unread_messages_badge",
        partial: "admin/communications/unread_badge",
        locals: { count: Message.inbound.unread.count }
      )

      Turbo::StreamsChannel.broadcast_update_to(
        "unread_messages",
        target: "unread_inbound_count",
        partial: "admin/dashboard/unread_inbound_count",
        locals: { count: Message.inbound.unread.count }
      )
    end

    business_for_broadcast = business || Business.find_by("phone LIKE ?", "%#{key}")
    return unless business_for_broadcast

    Turbo::StreamsChannel.broadcast_replace_to(
      "business_conversations",
      target: ApplicationController.helpers.dom_id(business_for_broadcast, :conversation),
      partial: "admin/communications/business_conversation",
      locals: { business: business_for_broadcast }
    )
  end

  def conversation_key
    number = direction == "inbound" ? from_number : to_number
    number.to_s.gsub(/\s+/, "").last(10)
  end

  def normalize_numbers
    self.from_number = from_number.to_s.gsub(/\s+/, "")
    self.to_number = to_number.to_s.gsub(/\s+/, "")
  end
end
