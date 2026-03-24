class DeveloperTask
  include ActiveModel::Model

  DEFAULT_STATUSES = %w[pending acknowledged in_progress blocked completed cancelled].freeze
  STATUS_STYLES = {
    "pending" => "bg-slate-100 text-slate-700 ring-slate-200",
    "acknowledged" => "bg-blue-50 text-blue-700 ring-blue-200",
    "in_progress" => "bg-amber-50 text-amber-700 ring-amber-200",
    "blocked" => "bg-rose-50 text-rose-700 ring-rose-200",
    "completed" => "bg-emerald-50 text-emerald-700 ring-emerald-200",
    "cancelled" => "bg-slate-200 text-slate-600 ring-slate-300"
  }.freeze

  attr_accessor :id, :title, :description, :status, :source_key, :source_name,
                :priority, :business_name, :assignee, :external_url,
                :created_at, :updated_at, :raw

  def initialize(attributes = {})
    super
    self.raw ||= {}
    self.status = status.to_s.presence || "pending"
    self.title = title.to_s.presence || fallback_title
    self.source_name = source_name.to_s.presence || "External App"
  end

  def self.filter_status_options(tasks)
    (DEFAULT_STATUSES + tasks.map(&:status)).uniq
  end

  def status_label
    status.to_s.humanize
  end

  def status_options
    (DEFAULT_STATUSES + [ status.to_s ]).uniq
  end

  def status_classes
    STATUS_STYLES.fetch(status.to_s, "bg-slate-100 text-slate-700 ring-slate-200")
  end

  def updated_sort_at
    updated_at || created_at || Time.zone.at(0)
  end

  private

  def fallback_title
    id.present? ? "Task ##{id}" : "Untitled Task"
  end
end
