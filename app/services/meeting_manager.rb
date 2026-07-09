class MeetingManager
  class SyncError < StandardError; end

  def initialize(google_calendar: GoogleCalendarService.new)
    @google_calendar = google_calendar
  end

  def create!(meeting)
    meeting.transaction do
      meeting.save!
      sync_google_event!(meeting, action: :create)
      meeting
    end
  rescue GoogleCalendarService::ConfigurationError, Google::Apis::Error => e
    raise SyncError, e.message
  end

  def update!(meeting, attributes)
    meeting.transaction do
      meeting.assign_attributes(attributes)
      meeting.save!
      sync_google_event!(meeting, action: :update) if meeting.google_event_id.present?
      meeting
    end
  rescue GoogleCalendarService::ConfigurationError, Google::Apis::Error => e
    raise SyncError, e.message
  end

  def cancel!(meeting)
    meeting.transaction do
      @google_calendar.cancel_event!(meeting) if meeting.google_event_id.present?
      meeting.update!(status: :cancelled)
      meeting
    end
  rescue GoogleCalendarService::ConfigurationError, Google::Apis::Error => e
    raise SyncError, e.message
  end

  private

  def sync_google_event!(meeting, action:)
    result =
      case action
      when :create
        @google_calendar.create_event!(meeting)
      when :update
        @google_calendar.update_event!(meeting)
      end

    meeting.update!(
      google_event_id: result[:google_event_id],
      google_meet_url: result[:google_meet_url]
    )
  end
end
