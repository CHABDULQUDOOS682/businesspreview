# frozen_string_literal: true

module Admin::TwilioBalanceHelper
  def twilio_balance_amount_label(balance)
    return "Unavailable" unless balance&.available?

    unit = balance.currency == "USD" ? "$" : "#{balance.currency} "
    "#{unit}#{number_with_precision(balance.amount, precision: 2, delimiter: ',')}"
  end

  def twilio_balance_updated_label(balance)
    return nil unless balance&.fetched_at

    "Updated #{time_ago_in_words(balance.fetched_at)} ago"
  end
end
