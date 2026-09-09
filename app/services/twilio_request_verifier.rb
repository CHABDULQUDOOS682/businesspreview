# frozen_string_literal: true

# Validates that an inbound webhook really came from Twilio by checking the
# X-Twilio-Signature header against our account auth token.
#
# Without this, `POST /twilio/connect` is an open relay: anyone can hand it a
# phone number and we return TwiML that dials it on our account.
class TwilioRequestVerifier
  SIGNATURE_HEADER = "HTTP_X_TWILIO_SIGNATURE"

  def self.valid?(request)
    new(request).valid?
  end

  # Verification is on everywhere except local development/test, where requests
  # are hand-rolled rather than signed. TWILIO_VERIFY_WEBHOOKS forces it either
  # way so the behaviour can be exercised locally and in specs.
  def self.enabled?
    override = ENV["TWILIO_VERIFY_WEBHOOKS"]
    return ActiveModel::Type::Boolean.new.cast(override) if override.present?

    !Rails.env.local?
  end

  def initialize(request)
    @request = request
  end

  def valid?
    return true unless self.class.enabled?
    return false if auth_token.blank? || signature.blank?

    validator.validate(url, payload, signature)
  rescue StandardError => e
    Rails.logger.error("[TwilioRequestVerifier] #{e.class}: #{e.message}")
    false
  end

  private

  def validator
    Twilio::Security::RequestValidator.new(auth_token)
  end

  def auth_token
    ENV["TWILIO_AUTH_TOKEN"].to_s
  end

  def signature
    @request.env[SIGNATURE_HEADER].to_s
  end

  def url
    @request.original_url
  end

  # Twilio signs the POST body params; query string params are already part of
  # the signed URL and must not be included again.
  def payload
    @request.request_parameters
  end
end
