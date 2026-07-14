class SchedulingController < ApplicationController
  skip_before_action :authenticate_user!
  layout "home"

  DAYS_AHEAD = 14

  before_action :set_owner
  before_action :set_selected_date, only: %i[new slots]

  def new
    @slots = SlotFinder.new(user: @owner).slots_for(@selected_date)
  end

  # Turbo Frame endpoint — renders just the slot list for the selected date,
  # so picking a different date doesn't reload the whole page.
  def slots
    @slots = SlotFinder.new(user: @owner).slots_for(@selected_date)
    render partial: "scheduling/slots", locals: { date: @selected_date, slots: @slots }
  end

  def create
    starts_at = parse_starts_at(params[:starts_at])
    if starts_at.blank?
      return redirect_to schedule_path, alert: "Please choose a time slot."
    end

    business = find_or_initialize_lead
    business.save!

    meeting = Meeting.new(
      user: @owner,
      business: business,
      client_name: params[:name],
      client_email: params[:email],
      client_phone: params[:phone],
      title: "Discovery Call with DevDeBizz Team",
      description: params[:message],
      starts_at: starts_at,
      duration_minutes: Meeting::DEFAULT_DURATION_MINUTES
    )

    MeetingManager.new.create!(meeting)
    redirect_to schedule_confirmation_path(token: meeting.public_token)
  rescue ActiveRecord::RecordInvalid
    redirect_to schedule_path(date: starts_at&.to_date), alert: "That time was just booked — please pick another."
  rescue MeetingManager::SyncError
    redirect_to schedule_path(date: starts_at&.to_date), alert: "Something went wrong booking your meeting. Please try again."
  end

  def confirmation
    @meeting = Meeting.find_by!(public_token: params[:token])
  end

  private

  def set_owner
    @owner = SlotFinder.scheduling_owner
  end

  def set_selected_date
    @selected_date = Date.parse(params[:date]) if params[:date].present?
    @selected_date ||= Date.current
  rescue ArgumentError
    @selected_date = Date.current
  end

  def bookable_dates
    (Date.current...(Date.current + DAYS_AHEAD.days)).to_a
  end
  helper_method :bookable_dates

  def parse_starts_at(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def find_or_initialize_lead
    business = Business.find_or_initialize_by(phone: params[:phone].to_s.strip)
    business.name = params[:company].presence || params[:name] if business.name.blank?
    business.owner_name ||= params[:name]
    business.email ||= params[:email]
    business
  end
end
