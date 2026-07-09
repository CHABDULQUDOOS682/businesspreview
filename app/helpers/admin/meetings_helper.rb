module Admin::MeetingsHelper
  STATUS_BADGE_CLASSES = {
    "scheduled" => "bg-accent-blue-bg text-accent-blue ring-sand-200",
    "completed" => "bg-accent-green-bg text-accent-green ring-sand-200",
    "cancelled" => "bg-sand-100 text-sand-600 ring-sand-200",
    "no_show" => "bg-accent-amber-bg text-accent-amber ring-sand-200"
  }.freeze

  DURATION_PRESETS = [ 15, 30, 45, 60, 90 ].freeze

  def meeting_status_badge(meeting)
    classes = STATUS_BADGE_CLASSES.fetch(meeting.status, "bg-sand-100 text-sand-600 ring-sand-200")
    content_tag(:span, meeting.status.humanize, class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset #{classes}")
  end

  def meeting_datetime(meeting)
    meeting.starts_at.in_time_zone.strftime("%b %-d, %Y at %-I:%M %p")
  end

  def meeting_time_range(meeting)
    "#{meeting.starts_at.in_time_zone.strftime('%-I:%M %p')} - #{meeting.ends_at.in_time_zone.strftime('%-I:%M %p')}"
  end

  def meeting_calendar_day_classes(day, selected_date, calendar_month)
    classes = [ "min-h-28 rounded-lg border p-2 transition" ]
    classes << (day.month == calendar_month.month ? "bg-white border-slate-200" : "bg-slate-50 border-slate-100 text-slate-400")
    classes << "ring-2 ring-indigo-500 border-indigo-500" if day == selected_date
    classes << "bg-indigo-50 border-indigo-200" if day == Date.current
    classes.join(" ")
  end

  def meeting_businesses_json(businesses)
    meeting_businesses_hash(businesses).to_json
  end

  def meeting_businesses_hash(businesses)
    businesses.each_with_object({}) do |business, hash|
      hash[business.id.to_s] = {
        name: business.name,
        client_name: business.owner_name.presence || business.name,
        email: business.email.to_s,
        phone: business.phone.to_s
      }
    end
  end

  def calendar_nav_params(month:, date: nil)
    {
      month: month.strftime("%Y-%m"),
      date: date,
      employee_id: params[:employee_id],
      business_id: params[:business_id],
      status: params[:status],
      q: params[:q]
    }.compact
  end
end
