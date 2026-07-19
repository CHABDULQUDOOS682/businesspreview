# frozen_string_literal: true

class CallLogRecorder
  def self.record_outbound!(user:, to_number:, business: nil, twilio_call_sid: nil, from_number: nil, status: "initiated")
    business ||= find_business_for_phone(to_number)
    attrs = {
      user: user,
      business: business,
      from_number: from_number.presence || ENV["TWILIO_PHONE_NUMBER"],
      to_number: to_number,
      direction: "outbound",
      status: status
    }

    if twilio_call_sid.present?
      call_log = CallLog.find_or_initialize_by(twilio_call_sid: twilio_call_sid)
      call_log.assign_attributes(attrs)
      call_log.save!
      call_log
    else
      CallLog.create!(attrs.merge(twilio_call_sid: nil))
    end
  end

  def self.find_business_for_phone(number)
    digits = number.to_s.gsub(/\D/, "")
    last10 = digits.last(10)
    return if last10.blank?

    Business.find_by(phone: number) ||
      Business.find_by("phone LIKE ?", "%#{last10}")
  end
end
