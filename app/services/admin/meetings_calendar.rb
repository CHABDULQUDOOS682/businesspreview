module Admin
  class MeetingsCalendar
    attr_reader :month

    def initialize(month:, meetings:)
      @month = month.to_date.beginning_of_month
      @meetings_by_date = meetings.group_by { |meeting| meeting.starts_at.in_time_zone.to_date }
    end

    def weeks
      start_date = month.beginning_of_week(:sunday)
      end_date = month.end_of_month.end_of_week(:sunday)
      (start_date..end_date).to_a.in_groups_of(7)
    end

    def meetings_on(date)
      @meetings_by_date[date.to_date] || []
    end

    def meeting_count_on(date)
      meetings_on(date).size
    end
  end
end
