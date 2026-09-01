# frozen_string_literal: true

module Admin::TwilioBalanceLoadable
  extend ActiveSupport::Concern

  included do
    before_action :load_twilio_balance, if: :twilio_balance_visible?
  end

  private

  def twilio_balance_visible?
    user_signed_in? && (super_admin? || admin_role?)
  end

  def load_twilio_balance
    @twilio_balance = TwilioBalanceService.fetch
  end
end
