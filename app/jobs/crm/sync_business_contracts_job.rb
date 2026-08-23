# frozen_string_literal: true

module Crm
  class SyncBusinessContractsJob < ApplicationJob
    queue_as :default

    discard_on ActiveRecord::RecordNotFound
    discard_on Crm::WebhookClient::ConfigurationError

    retry_on Crm::WebhookClient::Error, wait: :polynomially_longer, attempts: 5

    def perform(business_id)
      business = Business.find(business_id)
      client = Crm::WebhookClient.new(business)
      raise Crm::WebhookClient::ConfigurationError, "CRM webhook is not configured" unless client.configured?

      business.contracts.where.not(status: "void").find_each do |contract|
        event = contract.signed? ? "contract_signed" : "contract_sent"
        Crm::ContractEventNotifier.new(contract: contract).call(event)
      end
    end
  end
end
