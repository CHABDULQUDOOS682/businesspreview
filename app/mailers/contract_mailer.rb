# frozen_string_literal: true

class ContractMailer < ApplicationMailer
  def sign_request
    @contract = params[:contract]
    @business = @contract.business
    @sign_url = client_contract_url(
      @contract.access_token,
      host: ENV.fetch("APP_HOST", "localhost"),
      protocol: ENV.fetch("APP_PROTOCOL", "https")
    )

    mail(
      to: @contract.client_email,
      subject: "Please review and sign: #{@contract.title}"
    )
  end

  def signed_confirmation
    @contract = params[:contract]
    @business = @contract.business

    mail(
      to: @contract.client_email,
      subject: "Signed agreement: #{@contract.title}"
    )
  end
end
