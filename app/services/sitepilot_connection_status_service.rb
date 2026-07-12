# frozen_string_literal: true

class SitepilotConnectionStatusService
  Result = Struct.new(:ok, :http_status, :payload, keyword_init: true)

  REQUIRED_FIELDS = {
    "business_number" => "Business Number",
    "site_external_id" => "Site External ID",
    "site_api_base_url" => "Site API Base URL",
    "site_api_secret" => "Site API Secret"
  }.freeze

  def self.call(**kwargs)
    new(**kwargs).call
  end

  def initialize(business_number:, site_external_id: nil, site_api_base_url: nil, request_secret: nil)
    @business_number = business_number.to_s.strip
    @expected_slug = site_external_id.to_s.strip
    @expected_base_url = site_api_base_url.to_s.strip.delete_suffix("/")
    @request_secret = request_secret.to_s
  end

  def call
    if @business_number.blank?
      return failure(
        http_status: :unprocessable_entity,
        error: "business_number is required.",
        missing: [ REQUIRED_FIELDS["business_number"] ]
      )
    end

    business = Business.find_by(business_number: @business_number)
    unless business
      return failure(
        http_status: :not_found,
        error: "No preview_app business found with Business Number #{@business_number}. " \
               "Create or open that CRM business and paste SitePilot Connection values.",
        missing: [ REQUIRED_FIELDS["business_number"] ]
      )
    end

    missing = missing_fields(business)
    mismatches = field_mismatches(business)

    if missing.any? || mismatches.any?
      return failure(
        http_status: :unprocessable_entity,
        error: friendly_error(missing, mismatches),
        missing: missing,
        mismatches: mismatches,
        business_id: business.id
      )
    end

    if @request_secret.present? && !secure_match?(@request_secret, business.site_api_secret)
      return failure(
        http_status: :unauthorized,
        error: "Site API Secret in preview_app does not match SitePilot SITE_API_SECRET.",
        missing: [],
        mismatches: [ "Site API Secret" ],
        business_id: business.id
      )
    end

    Result.new(
      ok: true,
      http_status: :ok,
      payload: {
        ok: true,
        configured: true,
        business_number: business.business_number,
        site_external_id: business.site_external_id,
        site_api_base_url: business.site_api_base_url,
        message: "preview_app SitePilot Connection is configured for #{business.business_number}."
      }
    )
  end

  private

  def missing_fields(business)
    REQUIRED_FIELDS.filter_map do |attr, label|
      label if business.public_send(attr).blank?
    end
  end

  def field_mismatches(business)
    mismatches = []

    if @expected_slug.present? && business.site_external_id.present? &&
        business.site_external_id.to_s != @expected_slug
      mismatches << "Site External ID is “#{business.site_external_id}” but SitePilot slug is “#{@expected_slug}”"
    end

    if @expected_base_url.present? && business.site_api_base_url.present?
      actual = business.site_api_base_url.to_s.strip.delete_suffix("/")
      if actual.downcase != @expected_base_url.downcase
        mismatches << "Site API Base URL is “#{business.site_api_base_url}” but SitePilot expects “#{@expected_base_url}”"
      end
    end

    mismatches
  end

  def friendly_error(missing, mismatches)
    parts = []
    if missing.any?
      parts << "Missing in preview_app SitePilot Connection: #{missing.join(', ')}."
    end
    if mismatches.any?
      parts << "Mismatch: #{mismatches.join(' · ')}."
    end
    parts << "Open CRM → business → SitePilot Connection and paste the values from SitePilot → CRM tab."
    parts.join(" ")
  end

  def failure(http_status:, error:, missing:, mismatches: [], business_id: nil)
    Result.new(
      ok: false,
      http_status: http_status,
      payload: {
        ok: false,
        configured: false,
        error: error,
        missing: missing,
        mismatches: mismatches,
        business_id: business_id
      }.compact
    )
  end

  def secure_match?(left, right)
    return false if left.blank? || right.blank?
    return false unless left.bytesize == right.bytesize

    ActiveSupport::SecurityUtils.secure_compare(left, right)
  end
end
