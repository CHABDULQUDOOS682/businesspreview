class GoogleCalendar::WebhookSyncService
  GOOGLE_STATUSES = {
    "cancelled" => "cancelled"
  }.freeze

  def initialize(google_calendar: GoogleCalendarService.new)
    @google_calendar = google_calendar
  end

  def call(channel_id: nil, resource_state: nil)
    return unless @google_calendar.configured?

    channel = GoogleCalendarChannel.find_by(channel_id: channel_id) if channel_id.present?
    channel&.touch

    case resource_state
    when "sync"
      register_watch_if_needed
    when "exists", "not_exists"
      sync_recent_events
    else
      sync_recent_events
    end
  end

  private

  def register_watch_if_needed
    return if GoogleCalendarChannel.active.exists?

    @google_calendar.register_webhook!
  rescue Google::Apis::Error, GoogleCalendarService::ConfigurationError => e
    Rails.logger.warn("[GoogleCalendar::WebhookSyncService] watch registration failed: #{e.message}")
  end

  def sync_recent_events
    Meeting.scheduled.where.not(google_event_id: nil).find_each do |meeting|
      sync_meeting_from_google!(meeting)
    rescue Google::Apis::ClientError => e
      Rails.logger.warn("[GoogleCalendar::WebhookSyncService] skipped meeting #{meeting.id}: #{e.message}")
    end
  end

  def sync_meeting_from_google!(meeting)
    event = @google_calendar.fetch_event(meeting.google_event_id)
    mapped_status = GOOGLE_STATUSES[event.status]
    return if mapped_status.blank?
    return if meeting.status == mapped_status

    meeting.update!(status: mapped_status)
  end
end
