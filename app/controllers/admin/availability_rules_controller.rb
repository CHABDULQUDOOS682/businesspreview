class Admin::AvailabilityRulesController < ApplicationController
  layout "admin"

  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  before_action :require_admin_or_super_admin!
  before_action :set_schedule_owner

  def edit
    @rules_by_day = @owner.availability_rules.index_by(&:day_of_week)
  end

  def update
    ActiveRecord::Base.transaction do
      @owner.availability_rules.destroy_all
      (params[:days] || {}).each do |day_of_week, window|
        next unless window[:enabled] == "1"

        @owner.availability_rules.create!(
          day_of_week: day_of_week.to_i,
          start_minute: minutes_from(window[:start_time]),
          end_minute: minutes_from(window[:end_time])
        )
      end
    end
    redirect_to edit_admin_availability_rules_path, notice: "Company availability updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edit_admin_availability_rules_path, alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_schedule_owner
    @owner = SlotFinder.scheduling_owner
    return if @owner.present?

    redirect_to admin_root_path, alert: "No scheduling owner is configured. Set SCHEDULING_OWNER_EMAIL or create a super admin."
  end

  def minutes_from(hhmm)
    hour, minute = hhmm.to_s.split(":").map(&:to_i)
    (hour * 60) + minute
  end
end
