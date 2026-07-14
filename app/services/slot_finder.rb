class SlotFinder
  DEFAULT_STEP_MINUTES = 30

  def self.scheduling_owner
    User.find_by(email: ENV["SCHEDULING_OWNER_EMAIL"]) || User.role_super_admin.first
  end

  def initialize(user:, duration_minutes: Meeting::DEFAULT_DURATION_MINUTES, step_minutes: DEFAULT_STEP_MINUTES, excluding_id: nil)
    @user = user
    @duration_minutes = duration_minutes
    @step_minutes = step_minutes
    @excluding_id = excluding_id
  end

  # Returns open start times for the date using the owner's AvailabilityRule windows
  # and company-wide Meeting overlap rules (shared with /schedule + all dashboards).
  def slots_for(date)
    return [] if @user.blank?

    @user.availability_rules.active.for_day(date.wday).flat_map { |rule| candidates(date, rule) }
         .select { |start_time| available?(start_time) }
         .sort
  end

  private

  def candidates(date, rule)
    finish = rule.end_time_on(date)
    times = []
    t = rule.start_time_on(date)
    while t + @duration_minutes.minutes <= finish
      times << t
      t += @step_minutes.minutes
    end
    times
  end

  def available?(start_time)
    return false if start_time < Time.current

    !Meeting.overlapping(start_time, start_time + @duration_minutes.minutes, excluding_id: @excluding_id)
            .exists?
  end
end
