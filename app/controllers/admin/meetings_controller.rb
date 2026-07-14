class Admin::MeetingsController < ApplicationController
  layout "admin"

  before_action :set_meeting, only: %i[edit update cancel]
  before_action :ensure_meeting!, only: %i[edit update cancel]
  before_action :authorize_meeting_access!, only: %i[edit update cancel]

  def index
    @users = User.order(:name, :email)
    @businesses = Business.order(:name)
    @calendar_month = calendar_month_from_params
    @selected_date = selected_date_from_params(@calendar_month)
    @calendar_meetings = calendar_meetings_scope
    @calendar = Admin::MeetingsCalendar.new(month: @calendar_month, meetings: @calendar_meetings)
    @day_meetings = @calendar.meetings_on(@selected_date)
    @meeting = Meeting.new(default_meeting_attributes(date: @selected_date))
    @total_count = scoped_meetings.count
    @upcoming_count = scoped_meetings.upcoming.count
    assign_slot_picker_locals(@meeting, date: @selected_date)
  end

  def new
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @meeting = Meeting.new(default_meeting_attributes(date: date))
    assign_slot_picker_locals(@meeting, date: date)
  end

  def create
    @meeting = scoped_meetings.build(normalized_meeting_params)
    @meeting.user = current_user

    MeetingManager.new.create!(@meeting)
    redirect_to admin_meetings_path(calendar_redirect_params(@meeting)), notice: "Meeting scheduled and Google Calendar invite sent."
  rescue ActiveRecord::RecordInvalid
    @users = User.order(:name, :email)
    @businesses = Business.order(:name)
    @calendar_month = @meeting.starts_at&.to_date&.beginning_of_month || Date.current.beginning_of_month
    @selected_date = @meeting.starts_at&.to_date || Date.current
    @calendar = Admin::MeetingsCalendar.new(month: @calendar_month, meetings: calendar_meetings_scope)
    @day_meetings = @calendar.meetings_on(@selected_date)
    @total_count = scoped_meetings.count
    @upcoming_count = scoped_meetings.upcoming.count
    assign_slot_picker_locals(@meeting)
    render :index, status: :unprocessable_entity
  rescue MeetingManager::SyncError => e
    redirect_to admin_meetings_path(date: params.dig(:meeting, :meeting_date)), alert: "Meeting could not be synced to Google Calendar: #{e.message}"
  end

  def edit
    assign_slot_picker_locals(@meeting)
  end

  def update
    MeetingManager.new.update!(@meeting, normalized_meeting_params)
    redirect_to admin_meetings_path(calendar_redirect_params(@meeting)), notice: "Meeting updated."
  rescue ActiveRecord::RecordInvalid
    assign_slot_picker_locals(@meeting)
    render :edit, status: :unprocessable_entity
  rescue MeetingManager::SyncError => e
    flash.now[:alert] = "Meeting could not be synced to Google Calendar: #{e.message}"
    assign_slot_picker_locals(@meeting)
    render :edit, status: :unprocessable_entity
  end

  def cancel
    unless @meeting.cancellable?
      redirect_to admin_meetings_path(calendar_redirect_params(@meeting)), alert: "Only scheduled meetings can be cancelled."
      return
    end

    MeetingManager.new.cancel!(@meeting)
    redirect_to admin_meetings_path(calendar_redirect_params(@meeting)), notice: "Meeting cancelled."
  rescue MeetingManager::SyncError => e
    redirect_to admin_meetings_path(calendar_redirect_params(@meeting)), alert: "Meeting could not be cancelled in Google Calendar: #{e.message}"
  end

  def slots
    date = parse_slots_date
    duration = params[:duration_minutes].presence&.to_i || Meeting::DEFAULT_DURATION_MINUTES
    excluding_id = params[:excluding_id].presence
    selected = params[:selected].presence
    owner = SlotFinder.scheduling_owner
    slots = SlotFinder.new(
      user: owner,
      duration_minutes: duration,
      excluding_id: excluding_id
    ).slots_for(date)

    render partial: "admin/meetings/slots", locals: { date: date, slots: slots, selected: selected }
  end

  private

  def assign_slot_picker_locals(meeting, date: nil)
    @slot_date = meeting.starts_at&.to_date || date || Date.current
    @slot_duration = meeting.duration_minutes.presence || Meeting::DEFAULT_DURATION_MINUTES
    @slot_excluding_id = meeting.persisted? ? meeting.id : nil
    @slot_selected = meeting.starts_at&.iso8601
    @available_slots = SlotFinder.new(
      user: SlotFinder.scheduling_owner,
      duration_minutes: @slot_duration,
      excluding_id: @slot_excluding_id
    ).slots_for(@slot_date)
  end

  def parse_slots_date
    Date.parse(params[:date])
  rescue ArgumentError, TypeError
    Date.current
  end

  def scoped_meetings
    scope = Meeting.all
    scope = scope.for_employee(current_user) if employee_role?
    scope
  end

  def filtered_meetings
    scope = scoped_meetings.includes(:user, :business)
    scope = scope.where(user_id: params[:employee_id]) if filterable_employee? && params[:employee_id].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(business_id: params[:business_id]) if params[:business_id].present?

    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.left_outer_joins(:business, :user).where(
        "meetings.client_name ILIKE :q OR meetings.client_email ILIKE :q OR meetings.title ILIKE :q OR businesses.name ILIKE :q OR users.email ILIKE :q OR users.name ILIKE :q",
        q: q
      )
    end

    scope
  end

  def calendar_meetings_scope
    range_start = @calendar_month.beginning_of_month.beginning_of_week(:sunday).beginning_of_day
    range_end = @calendar_month.end_of_month.end_of_week(:sunday).end_of_day
    filtered_meetings.where(starts_at: range_start..range_end).order(:starts_at)
  end

  def calendar_month_from_params
    return Date.current.beginning_of_month if params[:month].blank?

    Date.strptime(params[:month], "%Y-%m")
  rescue ArgumentError
    Date.current.beginning_of_month
  end

  def selected_date_from_params(calendar_month)
    date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    date = calendar_month if date.month != calendar_month.month
    date
  rescue ArgumentError
    Date.current
  end

  def set_meeting
    @meeting = scoped_meetings.find_by(id: params[:id])
  end

  def ensure_meeting!
    return if @meeting.present?

    redirect_to admin_meetings_path, alert: "You do not have access to manage this meeting."
  end

  def authorize_meeting_access!
    return if super_admin? || admin_role?
    return if @meeting.user_id == current_user.id

    redirect_to admin_meetings_path, alert: "You do not have access to manage this meeting."
  end

  def filterable_employee?
    super_admin? || admin_role?
  end
  helper_method :filterable_employee?

  def default_meeting_attributes(date: Date.current)
    business = Business.find_by(id: params[:business_id])
    attrs = {
      duration_minutes: Meeting::DEFAULT_DURATION_MINUTES,
      starts_at: nil
    }

    if business.present?
      attrs.merge!(
        business_id: business.id,
        client_name: business.owner_name.presence || business.name,
        client_email: business.email,
        client_phone: business.phone,
        title: "Meeting with #{business.name}"
      )
    end

    attrs
  end

  def normalized_meeting_params
    attrs = meeting_params.to_h
    date = attrs.delete("meeting_date")
    time = attrs.delete("meeting_time")
    raw_starts_at = attrs.delete("starts_at")

    if raw_starts_at.present?
      attrs[:starts_at] = Time.zone.parse(raw_starts_at.to_s)
    elsif date.present?
      attrs[:starts_at] = Time.zone.parse("#{date} #{time.presence || '10:00'}")
    end

    attrs
  end

  def meeting_params
    params.require(:meeting).permit(
      :business_id,
      :client_name,
      :client_email,
      :client_phone,
      :title,
      :description,
      :starts_at,
      :meeting_date,
      :meeting_time,
      :duration_minutes
    )
  end

  def calendar_redirect_params(meeting)
    {
      month: meeting.starts_at.strftime("%Y-%m"),
      date: meeting.starts_at.to_date,
      employee_id: params[:employee_id],
      business_id: params[:business_id],
      status: params[:status],
      q: params[:q]
    }.compact
  end
end
