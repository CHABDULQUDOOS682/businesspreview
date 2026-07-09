class GoogleCalendar::RenewWatchJob < ApplicationJob
  queue_as :default

  def perform
    return unless GoogleCalendarService.new.configured?

    if GoogleCalendarChannel.active.exists?
      Rails.logger.info("[GoogleCalendar::RenewWatchJob] active watch channel already registered")
      return
    end

    GoogleCalendarService.new.register_webhook!
  rescue GoogleCalendarService::ConfigurationError, Google::Apis::Error => e
    Rails.logger.error("[GoogleCalendar::RenewWatchJob] #{e.message}")
  end
end
