class TwilioCallLogService
  Record = Struct.new(
    :sid,
    :from_number,
    :to_number,
    :direction,
    :status,
    :duration_seconds,
    :logged_at,
    :business,
    keyword_init: true
  ) do
    def duration_label
      return "-" if duration_seconds.blank? || duration_seconds.zero?

      minutes = duration_seconds / 60
      seconds = duration_seconds % 60
      format("%d:%02d", minutes, seconds)
    end

    def direction_label
      direction.to_s.titleize
    end
  end

  DEFAULT_LIMIT = 100

  def initialize(client: TWILIO_CLIENT, businesses: Business.all)
    @client = client
    @businesses = businesses
  end

  def recent_calls(limit: DEFAULT_LIMIT)
    business_by_phone = business_phone_index

    @client.calls.list(limit: limit).map do |call|
      from_number = call.from.to_s
      to_number = call.to.to_s

      Record.new(
        sid: call.sid,
        from_number: from_number,
        to_number: to_number,
        direction: normalize_direction(call.direction),
        status: call.status,
        duration_seconds: call.duration.to_i,
        logged_at: call.start_time || call.date_created,
        business: business_by_phone[phone_key(to_number)] || business_by_phone[phone_key(from_number)]
      )
    end
  end

  private

  def business_phone_index
    @businesses.each_with_object({}) do |business, index|
      key = phone_key(business.phone)
      index[key] ||= business if key.present?
    end
  end

  def phone_key(number)
    digits = number.to_s.gsub(/\D/, "")
    digits.last(10).presence
  end

  def normalize_direction(direction)
    direction.to_s.start_with?("inbound") ? "inbound" : "outbound"
  end
end
