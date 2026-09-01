# frozen_string_literal: true

class TwilioBalanceService
  CACHE_KEY = "twilio/account_balance"
  CACHE_TTL = 10.minutes

  Result = Struct.new(:amount, :currency, :fetched_at, :error, keyword_init: true) do
    def available?
      error.blank? && !amount.nil?
    end
  end

  def self.fetch(client: TWILIO_CLIENT)
    new(client: client).fetch
  end

  def initialize(client: TWILIO_CLIENT)
    @client = client
  end

  def fetch
    cached = Rails.cache.read(CACHE_KEY)
    return cached if cached&.available?

    result = load_balance
    Rails.cache.write(CACHE_KEY, result, expires_in: CACHE_TTL) if result.available?
    result
  end

  private

  def load_balance
    record = @client.api.v2010.balance.fetch

    Result.new(
      amount: BigDecimal(record.balance.to_s),
      currency: record.currency.to_s.upcase,
      fetched_at: Time.current,
      error: nil
    )
  rescue Twilio::REST::RestError, StandardError => e
    Result.new(amount: nil, currency: nil, fetched_at: Time.current, error: e.message)
  end
end
