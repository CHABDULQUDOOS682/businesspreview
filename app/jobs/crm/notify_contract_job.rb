# frozen_string_literal: true

module Crm
  class NotifyContractJob < ApplicationJob
    queue_as :default

    discard_on ActiveRecord::RecordNotFound
    discard_on Crm::WebhookClient::ConfigurationError

    retry_on Crm::WebhookClient::Error, wait: :polynomially_longer, attempts: 5

    def perform(contract_id, event)
      contract = Contract.find(contract_id)
      Crm::ContractEventNotifier.new(contract: contract).call(event)
    end
  end
end
