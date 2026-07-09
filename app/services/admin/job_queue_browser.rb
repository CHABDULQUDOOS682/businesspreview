# frozen_string_literal: true

module Admin
  class JobQueueBrowser
    FILTERS = %w[all pending running scheduled blocked failed finished].freeze

    attr_reader :filter, :queue_name, :class_name

    def initialize(filter: "all", queue_name: nil, class_name: nil)
      @filter = FILTERS.include?(filter.to_s) ? filter.to_s : "all"
      @queue_name = queue_name.presence
      @class_name = class_name.presence
    end

    def jobs
      scope = base_scope
      scope = scope.where(queue_name: queue_name) if queue_name
      scope = scope.where(class_name: class_name) if class_name
      apply_filter(scope).order(created_at: :desc)
    end

    def stats
      unfinished = SolidQueue::Job.where(finished_at: nil)
      {
        all: SolidQueue::Job.count,
        pending: unfinished.joins(:ready_execution).count,
        running: unfinished.joins(:claimed_execution).count,
        scheduled: unfinished.joins(:scheduled_execution).where("solid_queue_jobs.scheduled_at > ?", Time.current).count,
        blocked: unfinished.joins(:blocked_execution).count,
        failed: SolidQueue::Job.failed.where(finished_at: nil).count,
        finished: SolidQueue::Job.finished.count
      }
    end

    def worker_processes
      SolidQueue::Process.order(last_heartbeat_at: :desc).limit(20)
    end

    def recurring_tasks
      SolidQueue::RecurringTask.order(:key)
    end

    def queue_names
      SolidQueue::Job.distinct.order(:queue_name).pluck(:queue_name)
    end

    def class_names
      SolidQueue::Job.distinct.order(:class_name).pluck(:class_name)
    end

    def self.display_status(job)
      return "finished" if job.finished?
      return "failed" if job.failed?
      return "running" if job.claimed?
      return "blocked" if job.blocked?
      return "scheduled" if job.scheduled? && !job.due?
      return "pending" if job.ready?

      "unknown"
    end

    def self.short_class_name(job)
      job.class_name.to_s.demodulize
    end

    def self.arguments_summary(job)
      payload = job.arguments
      return "—" unless payload.is_a?(Hash)

      args = payload["arguments"]
      return "—" if args.blank?

      args.map { |arg| summarize_argument(arg) }.join(", ")
    end

    def self.summarize_argument(arg)
      case arg
      when Hash
        if arg["_aj_globalid"].present?
          GlobalID::Locator.locate(arg["_aj_globalid"])&.to_s || arg["_aj_globalid"]
        else
          arg.to_json.truncate(80)
        end
      else
        arg.to_s.truncate(80)
      end
    rescue StandardError
      arg.to_s.truncate(80)
    end

    private

    def base_scope
      SolidQueue::Job.includes(
        :ready_execution,
        :claimed_execution,
        :scheduled_execution,
        :failed_execution,
        :blocked_execution
      )
    end

    def apply_filter(scope)
      case filter
      when "pending"
        scope.where(finished_at: nil).joins(:ready_execution)
      when "running"
        scope.where(finished_at: nil).joins(:claimed_execution)
      when "scheduled"
        scope.where(finished_at: nil).joins(:scheduled_execution)
          .where("solid_queue_jobs.scheduled_at > ?", Time.current)
      when "blocked"
        scope.where(finished_at: nil).joins(:blocked_execution)
      when "failed"
        scope.failed.where(finished_at: nil)
      when "finished"
        scope.finished
      else
        scope
      end
    end
  end
end
