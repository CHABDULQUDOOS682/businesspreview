# frozen_string_literal: true

class PhoneLookupJob < ApplicationJob
  queue_as :default

  def perform(business_id)
    business = Business.find(business_id)
    return if business.phone.blank?

    lookup = TWILIO_CLIENT.lookups.v2
                         .phone_numbers(business.phone)
                         .fetch(fields: "line_type_intelligence")

    # Twilio Lookup v2 returns line_type_intelligence as a Hash with a "type" key.
    line_type = lookup.line_type_intelligence&.dig("type")

    business.update!(
      phone_line_type: line_type,
      phone_lookup_checked_at: Time.current,
      phone_lookup_error: nil
    )
  rescue Twilio::REST::RestError => e
    business.update!(phone_lookup_checked_at: Time.current, phone_lookup_error: e.message)
    Rails.logger.error("[PhoneLookupJob] business ##{business_id}: #{e.message}")
  rescue ActiveRecord::RecordNotFound
    # business was deleted before the job ran
  end
end
