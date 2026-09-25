# frozen_string_literal: true

# Classifies a business phone as mobile/landline/voip using phonelib
# (offline libphonenumber data — no Twilio Lookup charges).
class PhoneLookupJob < ApplicationJob
  queue_as :default

  TYPE_MAP = {
    mobile: "mobile",
    fixed_line: "landline",
    fixed_or_mobile: "fixed_or_mobile",
    voip: "voip",
    toll_free: "toll_free",
    premium_rate: "premium_rate",
    shared_cost: "shared_cost",
    personal_number: "personal_number",
    pager: "pager",
    uan: "uan",
    voicemail: "voicemail",
    unknown: "unknown"
  }.freeze

  def perform(business_id)
    business = Business.find(business_id)
    return if business.phone.blank?

    parsed = Phonelib.parse(business.phone)

    unless parsed.valid? || parsed.possible?
      business.update!(
        phone_line_type: nil,
        phone_lookup_checked_at: Time.current,
        phone_lookup_error: "Invalid phone number"
      )
      return
    end

    line_type = TYPE_MAP.fetch(parsed.type, parsed.type.to_s.presence || "unknown")

    business.update!(
      phone_line_type: line_type,
      phone_lookup_checked_at: Time.current,
      phone_lookup_error: nil
    )
  rescue ActiveRecord::RecordNotFound
    # business was deleted before the job ran
  rescue StandardError => e
    business&.update!(
      phone_lookup_checked_at: Time.current,
      phone_lookup_error: e.message.truncate(255)
    )
    Rails.logger.error("[PhoneLookupJob] business ##{business_id}: #{e.message}")
  end
end
