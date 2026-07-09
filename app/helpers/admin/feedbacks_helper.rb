module Admin::FeedbacksHelper
  STATUS_BADGE_CLASSES = {
    "pending" => "bg-slate-100 text-slate-700 ring-slate-200",
    "under_review" => "bg-blue-50 text-blue-700 ring-blue-200",
    "approved" => "bg-indigo-50 text-indigo-700 ring-indigo-200",
    "rejected" => "bg-red-50 text-red-700 ring-red-200",
    "planned" => "bg-purple-50 text-purple-700 ring-purple-200",
    "in_progress" => "bg-amber-50 text-amber-700 ring-amber-200",
    "testing" => "bg-cyan-50 text-cyan-700 ring-cyan-200",
    "completed" => "bg-green-50 text-green-700 ring-green-200",
    "closed" => "bg-slate-100 text-slate-600 ring-slate-200"
  }.freeze

  PRIORITY_BADGE_CLASSES = {
    "low" => "bg-slate-50 text-slate-600 ring-slate-200",
    "medium" => "bg-blue-50 text-blue-700 ring-blue-200",
    "high" => "bg-orange-50 text-orange-700 ring-orange-200",
    "critical" => "bg-red-50 text-red-700 ring-red-200"
  }.freeze

  TYPE_BADGE_CLASSES = {
    "bug" => "bg-red-50 text-red-700 ring-red-200",
    "feature_request" => "bg-indigo-50 text-indigo-700 ring-indigo-200",
    "improvement" => "bg-green-50 text-green-700 ring-green-200",
    "ui_ux" => "bg-purple-50 text-purple-700 ring-purple-200",
    "performance" => "bg-amber-50 text-amber-700 ring-amber-200",
    "documentation" => "bg-cyan-50 text-cyan-700 ring-cyan-200",
    "general" => "bg-slate-50 text-slate-700 ring-slate-200"
  }.freeze

  def feedback_status_badge(feedback)
    classes = STATUS_BADGE_CLASSES.fetch(feedback.status, "bg-slate-100 text-slate-600 ring-slate-200")
    content_tag(:span, feedback.status.humanize, class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset #{classes}")
  end

  def feedback_priority_badge(feedback)
    classes = PRIORITY_BADGE_CLASSES.fetch(feedback.priority, "bg-slate-100 text-slate-600 ring-slate-200")
    content_tag(:span, feedback.priority.humanize, class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset #{classes}")
  end

  def feedback_type_badge(feedback)
    classes = TYPE_BADGE_CLASSES.fetch(feedback.feedback_type, "bg-slate-100 text-slate-600 ring-slate-200")
    label = feedback.feedback_type.to_s.humanize
    content_tag(:span, label, class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset #{classes}")
  end

  def feedback_type_options
    Feedback::FEEDBACK_TYPES.map { |type| [ type.humanize, type ] }
  end

  def feedback_priority_options
    Feedback::PRIORITIES.map { |priority| [ priority.humanize, priority ] }
  end

  def feedback_status_options
    Feedback::STATUSES.map { |status| [ status.humanize, status ] }
  end
end
