# frozen_string_literal: true

class Admin::TasksController < ApplicationController
  layout "admin"

  def index
    @query = params[:q].to_s.strip
    @status_filter = params[:status].to_s.presence

    scope = AgencyTask.includes(:business).newest_first
    scope = scope.with_status(@status_filter)
    scope = scope.search(@query)

    @pagy, @tasks = pagy(scope)
    @status_options = AgencyTask::STATUSES
  end
end
