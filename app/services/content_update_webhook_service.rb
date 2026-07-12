# frozen_string_literal: true

class ContentUpdateWebhookService
  Result = Struct.new(:success?, :task, :error, :http_status, keyword_init: true)

  def self.call(payload:, secret:)
    new(payload: payload, secret: secret).call
  end

  def initialize(payload:, secret:)
    @payload = payload.is_a?(Hash) ? payload.deep_stringify_keys : {}
    @secret = secret.to_s
  end

  def call
    return failure("Missing X-Site-Api-Secret header", :unauthorized) if @secret.blank?

    business_number = @payload["business_number"].to_s.strip
    return failure("business_number is required", :unprocessable_entity) if business_number.blank?

    business = Business.find_by(business_number: business_number)
    return failure("Business not found for business_number #{business_number}", :not_found) if business.nil?

    if business.site_api_secret.blank?
      return failure("Site API secret is not configured for this business", :unauthorized)
    end

    unless ActiveSupport::SecurityUtils.secure_compare(business.site_api_secret, @secret)
      return failure("Invalid site API secret", :unauthorized)
    end

    content_update = @payload["content_update"]
    return failure("content_update is required", :unprocessable_entity) unless content_update.is_a?(Hash)

    external_id = content_update["id"].to_s.strip
    return failure("content_update.id is required", :unprocessable_entity) if external_id.blank?

    description = content_update["description"].to_s.strip
    title = description.presence&.truncate(120) || "Content update ##{external_id}"
    status = normalize_status(content_update["status"])

    task = AgencyTask.find_or_initialize_by(source: "content_update", external_id: external_id)
    task.assign_attributes(
      business: business,
      business_number: business_number,
      title: title,
      description: description.presence,
      status: status,
      external_url: content_update["admin_url"].presence,
      requester_name: content_update["requester_name"].presence,
      requester_email: content_update["requester_email"].presence,
      requested_at: parse_time(content_update["created_at"]) || task.requested_at || Time.current,
      raw_payload: @payload
    )
    task.save!

    Result.new(success?: true, task: task, http_status: :ok)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.to_sentence, :unprocessable_entity)
  end

  private

  def normalize_status(value)
    candidate = value.to_s.strip.presence || "pending"
    AgencyTask::STATUSES.include?(candidate) ? candidate : "pending"
  end

  def parse_time(value)
    return if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def failure(message, status)
    Result.new(success?: false, error: message, http_status: status)
  end
end
