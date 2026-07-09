# frozen_string_literal: true

module Admin::JobsHelper
  STATUS_LABELS = {
    "pending" => "Pending",
    "running" => "Running",
    "scheduled" => "Scheduled",
    "blocked" => "Blocked",
    "failed" => "Failed",
    "finished" => "Finished",
    "unknown" => "Unknown"
  }.freeze

  STATUS_BADGE_CLASSES = {
    "pending" => "bg-accent-amber-bg text-accent-amber ring-accent-amber/20",
    "running" => "bg-accent-blue-bg text-accent-blue ring-accent-blue/20",
    "scheduled" => "bg-accent-purple-bg text-accent-purple ring-accent-purple/20",
    "blocked" => "bg-sand-100 text-sand-700 ring-sand-200",
    "failed" => "bg-red-50 text-red-700 ring-red-200",
    "finished" => "bg-accent-green-bg text-accent-green ring-accent-green/20",
    "unknown" => "bg-sand-100 text-sand-600 ring-sand-200"
  }.freeze

  def admin_job_status_badge(job)
    status = Admin::JobQueueBrowser.display_status(job)
    label = STATUS_LABELS.fetch(status, status.humanize)
    classes = STATUS_BADGE_CLASSES.fetch(status, STATUS_BADGE_CLASSES["unknown"])

    content_tag(:span, label, class: "inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset #{classes}")
  end

  def admin_job_filter_link(label, status, browser)
    active = browser.filter == status
    classes = [
      "inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-sm font-medium ring-1 ring-inset transition",
      (active ? "bg-accent-blue text-white ring-accent-blue" : "bg-white text-sand-700 ring-sand-200 hover:bg-sand-50")
    ].join(" ")
    count = browser.stats[status.to_sym]

    link_to admin_jobs_path(status: status, queue_name: browser.queue_name, class_name: browser.class_name), class: classes do
      safe_join([ label, content_tag(:span, count, class: "rounded-full bg-white/20 px-1.5 text-xs font-semibold #{active ? '' : 'bg-sand-100 text-sand-600'}") ])
    end
  end

  def admin_job_arguments(job)
    payload = job.arguments
    return content_tag(:p, "—", class: "text-sm text-sand-500") unless payload.is_a?(Hash)

    tag.pre(JSON.pretty_generate(payload), class: "overflow-x-auto rounded-lg bg-sand-50 p-4 text-xs text-sand-800 ring-1 ring-sand-200")
  end

  def admin_job_error(job)
    execution = job.failed_execution
    return unless execution

    error_text = [
      "#{execution.exception_class}: #{execution.message}",
      Array(execution.backtrace).join("\n")
    ].compact.join("\n\n")

    tag.pre(error_text, class: "overflow-x-auto rounded-lg bg-red-50 p-4 text-xs text-red-800 ring-1 ring-red-200")
  end
end
