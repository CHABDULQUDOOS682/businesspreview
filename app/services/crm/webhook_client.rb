# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Crm
  class WebhookClient
    class Error < StandardError; end
    class ConfigurationError < StandardError; end

    def initialize(business)
      @business = business
    end

    def configured?
      @business.site_api_base_url.present? &&
        @business.site_api_secret.present? &&
        @business.business_number.present?
    end

    def deliver!(event:, **extras)
      raise ConfigurationError, "CRM webhook is not configured for business ##{@business.id}" unless configured?

      payload = {
        event: event.to_s,
        business_number: @business.business_number
      }
      extras.each do |key, value|
        next if value.nil?

        payload[key.to_sym] = value
      end

      post(payload)
    end

    private

    def post(body)
      uri = URI.join(normalized_base_url, "integrations/crm/webhooks")
      request = Net::HTTP::Post.new(uri)
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      request["X-Crm-Webhook-Secret"] = @business.site_api_secret
      request["X-Site-Api-Secret"] = @business.site_api_secret
      request.body = body.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 10

      response = http.request(request)
      return response if response.is_a?(Net::HTTPSuccess)

      raise Error, "CRM webhook failed with #{response.code}: #{response.body.to_s.truncate(200)}"
    end

    def normalized_base_url
      url = @business.site_api_base_url.to_s.strip
      url.end_with?("/") ? url : "#{url}/"
    end
  end
end
