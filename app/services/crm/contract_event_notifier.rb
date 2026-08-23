# frozen_string_literal: true

require "base64"

module Crm
  class ContractEventNotifier
    def initialize(contract:)
      @contract = contract
      @business = contract.business
      @client = WebhookClient.new(@business)
    end

    def call(event)
      return unless @client.configured?
      return unless %w[contract_sent contract_signed].include?(event.to_s)

      extras = {
        kind: @contract.kind,
        title: @contract.title,
        status: @contract.status,
        external_id: @contract.id.to_s,
        signed_at: @contract.client_signed_at&.iso8601,
        client_name: @contract.client_name,
        client_email: @contract.client_email
      }

      if @contract.document.attached?
        extras[:pdf_base64] = Base64.strict_encode64(@contract.document.download)
        extras[:pdf_filename] = @contract.document.filename.to_s
        extras[:pdf_content_type] = @contract.document.content_type
      end

      @client.deliver!(event: event, **extras)
    end
  end
end
