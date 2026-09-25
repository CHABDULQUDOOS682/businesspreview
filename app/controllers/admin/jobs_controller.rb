# frozen_string_literal: true

class Admin::JobsController < ApplicationController
  layout "admin"

  before_action :require_jobs_access!
  before_action :require_super_admin!, only: :enqueue_phone_lookup
  before_action :set_browser, only: :index
  before_action :set_job, only: %i[show retry]

  def index
    @stats = @browser.stats
    @pagy, @jobs = pagy(@browser.jobs, limit: 25)
    @worker_processes = @browser.worker_processes
    @recurring_tasks = @browser.recurring_tasks
    @unchecked_phone_count = Business.where.not(phone: [ nil, "" ]).where(phone_lookup_checked_at: nil).count
  end

  def show
  end

  def retry
    unless @job.failed? && !@job.finished?
      redirect_to admin_job_path(@job), alert: "Only failed jobs can be retried."
      return
    end

    @job.retry
    redirect_to admin_job_path(@job), notice: "Job queued for retry."
  end

  def enqueue_phone_lookup
    only_unchecked = ActiveModel::Type::Boolean.new.cast(params.fetch(:only_unchecked, true))
    PhoneLookupBatchJob.perform_later(only_unchecked: only_unchecked)

    notice =
      if only_unchecked
        "Phone lookup queued for unchecked businesses."
      else
        "Phone lookup queued for all businesses."
      end

    redirect_to admin_jobs_path, notice: notice
  end

  private

  def require_jobs_access!
    return if super_admin? || admin_role?

    redirect_to admin_root_path, alert: "You do not have permission to access background jobs."
  end

  def set_browser
    @browser = Admin::JobQueueBrowser.new(
      filter: params[:status],
      queue_name: params[:queue_name],
      class_name: params[:class_name]
    )
  end

  def set_job
    @job = SolidQueue::Job.includes(:failed_execution, :claimed_execution, :ready_execution).find(params[:id])
  end
end
