require "google/apis/calendar_v3"
require "googleauth"

class GoogleCalendarService
  class ConfigurationError < StandardError; end

  CALENDAR_SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize(calendar_service: nil)
    @calendar_service = calendar_service
  end

  def create_event!(meeting)
    ensure_configured!

    event = build_event(meeting, include_meet: true)
    created = calendar_service.insert_event(
      calendar_id,
      event,
      conference_data_version: 1,
      send_updates: "all"
    )

    {
      google_event_id: created.id,
      google_meet_url: extract_meet_url(created)
    }
  end

  def update_event!(meeting)
    ensure_configured!
    raise ConfigurationError, "Meeting is not linked to Google Calendar" if meeting.google_event_id.blank?

    existing = calendar_service.get_event(calendar_id, meeting.google_event_id)
    event = build_event(meeting, include_meet: false, existing_event: existing)

    updated = calendar_service.update_event(
      calendar_id,
      meeting.google_event_id,
      event,
      conference_data_version: existing.conference_data.present? ? 1 : 0,
      send_updates: "all"
    )

    {
      google_event_id: updated.id,
      google_meet_url: extract_meet_url(updated).presence || meeting.google_meet_url
    }
  end

  def cancel_event!(meeting)
    ensure_configured!
    return if meeting.google_event_id.blank?

    calendar_service.delete_event(calendar_id, meeting.google_event_id, send_updates: "all")
  end

  def fetch_event(event_id)
    ensure_configured!
    calendar_service.get_event(calendar_id, event_id)
  end

  def register_webhook!
    ensure_configured!
    return if webhook_url.blank?

    channel = Google::Apis::CalendarV3::Channel.new(
      id: SecureRandom.uuid,
      type: "web_hook",
      address: webhook_url
    )

    response = calendar_service.watch_event(calendar_id, channel)
    GoogleCalendarChannel.create!(
      channel_id: response.id,
      resource_id: response.resource_id,
      expires_at: Time.at(response.expiration.to_i / 1000)
    )
  end

  def configured?
    client_id.present? && client_secret.present? && refresh_token.present? && calendar_id.present?
  end

  private

  def ensure_configured!
    raise ConfigurationError, "Google Calendar is not configured" unless configured?
  end

  def calendar_service
    @calendar_service ||= begin
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = authorizer
      service
    end
  end

  def authorizer
    @authorizer ||= Google::Auth::UserRefreshCredentials.new(
      client_id: client_id,
      client_secret: client_secret,
      scope: CALENDAR_SCOPE,
      refresh_token: refresh_token
    )
  end

  def build_event(meeting, include_meet:, existing_event: nil)
    event = Google::Apis::CalendarV3::Event.new(
      summary: meeting.title,
      description: meeting_description(meeting),
      start: event_time(meeting.starts_at),
      end: event_time(meeting.ends_at),
      attendees: meeting.attendee_emails.map do |email|
        Google::Apis::CalendarV3::EventAttendee.new(email: email, response_status: "needsAction")
      end
    )

    if include_meet
      event.conference_data = Google::Apis::CalendarV3::ConferenceData.new(
        create_request: Google::Apis::CalendarV3::CreateConferenceRequest.new(
          request_id: SecureRandom.uuid,
          conference_solution_key: Google::Apis::CalendarV3::ConferenceSolutionKey.new(type: "hangoutsMeet")
        )
      )
    elsif existing_event&.conference_data.present?
      event.conference_data = existing_event.conference_data
    end

    event
  end

  def meeting_description(meeting)
    [
      meeting.description.presence,
      "Client: #{meeting.client_name}",
      "Business: #{meeting.business.name}",
      "Employee: #{meeting.user.display_name}",
      "Phone: #{meeting.client_phone.presence || 'N/A'}"
    ].compact.join("\n")
  end

  def event_time(time)
    Google::Apis::CalendarV3::EventDateTime.new(
      date_time: time.iso8601,
      time_zone: Time.zone.tzinfo.name
    )
  end

  def extract_meet_url(event)
    entry = event.conference_data&.entry_points&.find { |point| point.entry_point_type == "video" }
    entry&.uri
  end

  def client_id
    ENV["GOOGLE_CLIENT_ID"]
  end

  def client_secret
    ENV["GOOGLE_CLIENT_SECRET"]
  end

  def refresh_token
    ENV["GOOGLE_REFRESH_TOKEN"]
  end

  def calendar_id
    ENV.fetch("GOOGLE_CALENDAR_ID", Meeting.company_email)
  end

  def webhook_url
    ENV["GOOGLE_CALENDAR_WEBHOOK_URL"]
  end
end
