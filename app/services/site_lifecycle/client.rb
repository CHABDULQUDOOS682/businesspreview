require "json"
require "net/http"
require "uri"

module SiteLifecycle
  class Client
    class ConfigurationError < StandardError; end

    def initialize(business)
      @business = business
    end

    def deactivate!(payment_invoice:, reason: "subscription_overdue")
      post("/api/site_status/deactivate", payload(payment_invoice, reason))
    end

    def reactivate!(payment_invoice:, reason: "subscription_paid")
      post("/api/site_status/reactivate", payload(payment_invoice, reason))
    end

    def ping!(site_id: nil)
      body = { site_id: site_id.presence || self.site_id }.compact
      post("/api/site_status/ping", body)
    end

    def configured?
      base_url.present? && secret.present?
    end

    private

    def base_url
      @business.site_api_base_url.presence
    end

    def secret
      @business.site_api_secret.presence
    end

    def site_id
      @business.site_external_id.presence || @business.website_name.presence || @business.id.to_s
    end

    def payload(payment_invoice, reason)
      {
        site_id: site_id,
        business_id: @business.id,
        reason: reason,
        payment_invoice_id: payment_invoice&.id,
        overdue_since: payment_invoice&.sent_at&.iso8601,
        paid_at: payment_invoice&.paid_at&.iso8601
      }.compact
    end

    def post(path, body)
      raise ConfigurationError, "Site API is not configured for business ##{@business.id}" unless configured?

      uri = URI.join(normalized_base_url, path)
      request = Net::HTTP::Post.new(uri)
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      request["X-Site-Api-Secret"] = secret
      request.body = body.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 10

      response = http.request(request)
      return response if response.is_a?(Net::HTTPSuccess)

      raise ConfigurationError, "Site API request failed with #{response.code}: #{response.body.to_s.truncate(200)}"
    end

    def normalized_base_url
      url = base_url.to_s
      url.end_with?("/") ? url : "#{url}/"
    end
  end
end
