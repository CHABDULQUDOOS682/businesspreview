# frozen_string_literal: true

# Throttles for the endpoints a stranger can reach. Everything here is keyed by
# IP; the goal is to make spam and token enumeration expensive, not to be a WAF.
class Rack::Attack
  # solid_cache in production, memory locally. The test env uses a null store,
  # so specs swap in a real store before exercising these rules.
  self.cache.store = Rails.cache

  # Public forms that send email or create records.
  throttle("contact/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/contact"
  end

  throttle("schedule/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/schedule"
  end

  throttle("reviews/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/reviews"
  end

  throttle("contract-sign/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.post? && req.path.match?(%r{\A/contracts/[^/]+/sign\z})
  end

  # Unguessable tokens are only unguessable if guessing is slow.
  throttle("public-tokens/ip", limit: 30, period: 1.minute) do |req|
    if req.get? && req.path.match?(%r{\A/(lp|pay|contracts|reviews/new)/})
      req.ip
    end
  end

  throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period].to_i

    [
      429,
      { "Content-Type" => "text/plain", "Retry-After" => retry_after.to_s },
      [ "Too many requests. Please try again later.\n" ]
    ]
  end

  self.throttled_responder = throttled_responder
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  request = payload[:request]
  Rails.logger.warn(
    "[Rack::Attack] throttled #{request.request_method} #{request.path} from #{request.ip}"
  )
end
