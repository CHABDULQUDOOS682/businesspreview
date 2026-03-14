class Admin::CommunicationsController < ApplicationController
  layout "admin"

  def index
    # We want to show all businesses and their latest message if any
    # Plus any conversations that aren't linked to a business yet

    @businesses = Business.all.order(name: :asc)

    # Get latest message for each number that isn't already associated with a business
    @standalone_conversations = Message.where(business_id: nil)
                                      .select(Arel.sql("DISTINCT ON (CASE WHEN direction = 'inbound' THEN from_number ELSE to_number END) *"))
                                      .order(Arel.sql("CASE WHEN direction = 'inbound' THEN from_number ELSE to_number END, created_at DESC"))
                                      .sort_by(&:created_at).reverse
  end

  def show
    @number = params[:id] # The phone number we're chatting with
    @business = Business.find_by(phone: @number) ||
                Business.find_by("phone LIKE ?", "%#{@number.last(10)}") if @number.present?

    # Flexible matching for messages using the last 10 digits to ignore +, country codes, or formatting differences
    last_10 = @number.to_s.gsub(/\s+/, "").last(10)
    @conversation_key = last_10
    if last_10.present?
      # Match by business ID or by phone number patterns
      @messages = Message.where("from_number LIKE ? OR to_number LIKE ?", "%#{last_10}", "%#{last_10}")
      @messages = @messages.or(Message.where(business_id: @business.id)) if @business
      @messages = @messages.order(created_at: :asc)
      @last_inbound_at = @messages.inbound.maximum(:created_at)

      # Mark inbound messages as read for this conversation
      if @business
        @business.messages.inbound.unread.update_all(read_at: Time.current)
        Turbo::StreamsChannel.broadcast_replace_to(
          "business_conversations",
          target: ApplicationController.helpers.dom_id(@business, :conversation),
          partial: "admin/communications/business_conversation",
          locals: { business: @business }
        )
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
      else
        Message.inbound.unread.where("from_number LIKE ? OR to_number LIKE ?", "%#{last_10}", "%#{last_10}")
               .update_all(read_at: Time.current)
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
    else
      @messages = Message.none
    end
  end

  def create
    @number = params[:to_number]
    @body = params[:body]
    @business_id = params[:business_id]

    begin
      # Send SMS via Twilio
      SmsService.send_sms(to: @number, message: @body)

      # Record in database
      Message.create!(
        from_number: ENV["TWILIO_PHONE_NUMBER"],
        to_number: @number,
        body: @body,
        direction: "outbound",
        business_id: @business_id
      )

      redirect_to admin_communication_path(@number), notice: "Message sent successfully."
    rescue => e
      redirect_to admin_communication_path(@number), alert: "Failed to send message: #{e.message}"
    end
  end

  def call
    @number = params[:id]

    begin
      CallService.call(to: @number)
      redirect_to admin_communication_path(@number), notice: "Call initiated successfully."
    rescue => e
      redirect_to admin_communication_path(@number), alert: "Failed to initiate call: #{e.message}"
    end
  end
end
