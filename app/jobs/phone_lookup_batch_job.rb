# frozen_string_literal: true

# Enqueues PhoneLookupJob for existing businesses.
# Usage (console / one-off):
#   PhoneLookupBatchJob.perform_later                  # unchecked only
#   PhoneLookupBatchJob.perform_later(only_unchecked: false)  # re-check all
class PhoneLookupBatchJob < ApplicationJob
  queue_as :default

  def perform(only_unchecked: true)
    scope = Business.where.not(phone: [ nil, "" ])
    scope = scope.where(phone_lookup_checked_at: nil) if only_unchecked

    count = 0
    scope.find_each do |business|
      PhoneLookupJob.perform_later(business.id)
      count += 1
    end

    Rails.logger.info("[PhoneLookupBatchJob] queued #{count} lookup(s) (only_unchecked=#{only_unchecked})")
    count
  end
end
