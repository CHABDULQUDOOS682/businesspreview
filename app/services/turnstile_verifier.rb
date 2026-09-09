# frozen_string_literal: true

require "net/http"

# Cloudflare Turnstile — a CAPTCHA that is invisible to most real visitors.
# Only active once BOTH keys are configured. Requiring the secret alone would
# reject every submission (widget never renders, so no token is posted).
class TurnstileVerifier
  VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"
  TIMEOUT_SECONDS = 5

  def self.required?
    site_key.present? && secret_key.present? && !Rails.env.test?
  end

  def self.site_key
    ENV["TURNSTILE_SITE_KEY"].presence
  end

  def self.secret_key
    ENV["TURNSTILE_SECRET_KEY"].presence
  end

  def self.valid?(token, remote_ip: nil)
    return true unless required?
    return false if token.blank?

    new(token, remote_ip: remote_ip).valid?
  end

  def initialize(token, remote_ip: nil)
    @token = token
    @remote_ip = remote_ip
  end

  def valid?
    response = post_verification
    JSON.parse(response.body)["success"] == true
  rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
    Rails.logger.error("[TurnstileVerifier] #{e.class}: #{e.message}")
    false
  end

  private

  def post_verification
    uri = URI(VERIFY_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT_SECONDS
    http.read_timeout = TIMEOUT_SECONDS

    request = Net::HTTP::Post.new(uri)
    request.set_form_data(
      {
        "secret" => self.class.secret_key,
        "response" => @token,
        "remoteip" => @remote_ip
      }.compact
    )

    http.request(request)
  end
end
