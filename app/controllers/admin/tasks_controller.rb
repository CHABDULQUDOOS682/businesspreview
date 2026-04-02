class Admin::TasksController < ApplicationController
  layout "admin"

  def index
    @query = params[:q].to_s.strip
    @source_filter = params[:source].to_s.presence
    @status_filter = params[:status].to_s.presence

    client = DeveloperTasks::Client.new
    @task_sources = client.sources
    tasks, @source_errors = client.fetch_tasks
    @status_options = DeveloperTask.filter_status_options(tasks)

    @tasks = tasks
    @tasks = @tasks.select { |task| task.source_key == @source_filter } if @source_filter.present?
    @tasks = @tasks.select { |task| task.status == @status_filter } if @status_filter.present?
    @tasks = @tasks.select { |task| task_matches_query?(task, @query) } if @query.present?
    @pagy, @tasks = pagy_array(@tasks)
  end

  def update
    redirect_params = {
      q: params[:q].presence,
      source: params[:source_filter].presence,
      status: params[:status_filter].presence
    }.compact

    status = params[:status].to_s.strip
    if status.blank?
      redirect_to admin_tasks_path(redirect_params), alert: "Choose a status before saving."
      return
    end

    success, payload = DeveloperTasks::Client.new.update_status(
      source_key: params[:source_key],
      id: params[:id],
      status: status
    )

    if success
      redirect_to admin_tasks_path(redirect_params), notice: "Task ##{params[:id]} updated to #{status.humanize}."
    else
      redirect_to admin_tasks_path(redirect_params), alert: payload
    end
  end

  private

  def task_matches_query?(task, query)
    haystack = [
      task.title,
      task.description,
      task.source_name,
      task.business_name,
      task.assignee,
      task.priority,
      task.id
    ].compact.join(" ").downcase

    haystack.include?(query.downcase)
  end
end
