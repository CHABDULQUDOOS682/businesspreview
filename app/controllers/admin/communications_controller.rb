class Admin::CommunicationsController < ApplicationController
  layout "admin"

  before_action :authorize_conversation_access!, only: %i[show create call]

  def index
    # We want to show all businesses and their latest message if any
    # Plus any conversations that aren't linked to a business yet
    @segment = employee_role? ? "nurture" : Business.normalize_segment(params[:segment])
    @segment_counts = Business.segment_counts(accessible_businesses)
    @segment_unread_counts = Business.segment_unread_counts(accessible_businesses)
    @pagy, @businesses = pagy(accessible_businesses.for_segment(@segment).order(name: :asc))

    # Conversations from numbers we cannot attribute to a business have no
    # assignment to check, so they stay with admins.
    @standalone_conversations = if employee_role?
      []
    else
      Message.where(business_id: nil)
             .select(Arel.sql("DISTINCT ON (CASE WHEN direction = 'inbound' THEN from_number ELSE to_number END) *"))
             .order(Arel.sql("CASE WHEN direction = 'inbound' THEN from_number ELSE to_number END, created_at DESC"))
             .sort_by(&:created_at).reverse
    end
  end

  def show
    @number = params[:id] # The phone number we're chatting with
    @business = conversation_business

    # Flexible matching for messages using the last 10 digits to ignore +, country codes, or formatting differences
    last_10 = @number.to_s.gsub(/\s+/, "").last(10)
    @conversation_key = last_10
    if last_10.present?
      # Match by business ID or by phone number patterns
      # Use an array of IDs to keep the query simple and index-friendly
      conditions = [ "from_number LIKE :l10 OR to_number LIKE :l10", { l10: "%#{last_10}" } ]
      if @business
        @messages = Message.where("#{conditions[0]} OR business_id = :b_id",
                                  l10: "%#{last_10}", b_id: @business.id)
      else
        @messages = Message.where(conditions[0], conditions[1])
      end
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
        UnreadMessagesBroadcaster.broadcast!(business: @business)
      else
        Message.inbound.unread.where("from_number LIKE ? OR to_number LIKE ?", "%#{last_10}", "%#{last_10}")
               .update_all(read_at: Time.current)
        UnreadMessagesBroadcaster.broadcast!
      end
    else
      @messages = Message.none
    end
  end

  def create
    @number = params[:to_number]
    @body = params[:body]
    @business_id = permitted_business_id

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
      twilio_call = CallService.call(to: @number)
      CallLogRecorder.record_outbound!(
        user: current_user,
        to_number: @number,
        twilio_call_sid: twilio_call.sid,
        from_number: ENV["TWILIO_PHONE_NUMBER"],
        status: twilio_call.status.presence || "initiated"
      )
      redirect_to admin_communication_path(@number), notice: "Call initiated successfully."
    rescue => e
      redirect_to admin_communication_path(@number), alert: "Failed to initiate call: #{e.message}"
    end
  end

  private

  # Employees only ever see the businesses assigned to them; admins see everything.
  def accessible_businesses
    return Business.all unless employee_role?

    Business.assigned_to_user(current_user)
  end

  def conversation_number
    (params[:to_number].presence || params[:id]).to_s
  end

  def conversation_business
    number = conversation_number
    return nil if number.blank?

    Business.find_by(phone: number) ||
      Business.find_by("phone LIKE ?", "%#{number.gsub(/\s+/, '').last(10)}")
  end

  # Sending SMS and placing calls both spend company money and reach clients, so
  # an employee may only do it for a business assigned to them.
  def authorize_conversation_access!
    return unless employee_role?

    business = conversation_business
    return if business && business.assigned_to_id == current_user.id

    redirect_to admin_communications_path,
                alert: "You do not have access to that conversation."
  end

  def permitted_business_id
    requested = params[:business_id].presence
    return requested unless employee_role?

    accessible_businesses.where(id: requested).pick(:id)
  end
end
