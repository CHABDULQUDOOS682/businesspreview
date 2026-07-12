# frozen_string_literal: true

module Admin::TasksHelper
  STATUS_BADGE_CLASSES = {
    "pending" => "bg-amber-50 text-amber-700 ring-amber-200",
    "in_progress" => "bg-blue-50 text-blue-700 ring-blue-200",
    "completed" => "bg-green-50 text-green-700 ring-green-200",
    "rejected" => "bg-red-50 text-red-700 ring-red-200"
  }.freeze

  def agency_task_status_badge(task)
    classes = STATUS_BADGE_CLASSES.fetch(task.status, "bg-slate-100 text-slate-600 ring-slate-200")
    content_tag(
      :span,
      task.status_label,
      class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium ring-1 ring-inset #{classes}"
    )
  end
end
