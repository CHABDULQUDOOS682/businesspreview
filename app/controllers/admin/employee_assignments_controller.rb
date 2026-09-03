# frozen_string_literal: true

class Admin::EmployeeAssignmentsController < ApplicationController
  layout "admin"
  helper Admin::BusinessesHelper

  before_action :require_admin_or_super_admin!

  def index
    @assignee_options = User.role_employee.order(:name, :email)
    @employee_tab = resolve_employee_tab(params[:employee_id])
    @segment = Business.normalize_segment(params[:segment])
    @work_status = Business.normalize_work_status(params[:work_status])

    assigned_scope = Business.where.not(assigned_to_id: nil)
    assigned_scope = assigned_scope.assigned_to_user(@employee_tab) if @employee_tab

    segment_scope = assigned_scope.for_segment(@segment)
    @segment_counts = segment_counts_for(assigned_scope)
    @segment_unread_counts = segment_unread_counts_for(assigned_scope)
    @employee_tab_counts = employee_tab_counts
    @work_status_counts = work_status_counts_for(segment_scope)
    @work_status_total = segment_scope.count
    segment_scope = segment_scope.with_work_status(@work_status) if @work_status.present?

    @pagy, @businesses = pagy(
      apply_filters(segment_scope).includes(:assigned_to).order(created_at: :desc)
    )

    @niches = segment_scope.where.not(niche: [ nil, "" ]).distinct.pluck(:niche).sort
    @cities = segment_scope.where.not(city: [ nil, "" ]).distinct.pluck(:city).sort
    @countries = segment_scope.where.not(country: [ nil, "" ]).distinct.pluck(:country).sort
  end

  private

  def apply_filters(scope)
    scope = scope.where("LOWER(name) ILIKE LOWER(?)", "%#{params[:name]}%") if params[:name].present?
    scope = scope.where(niche: params[:niche]) if params[:niche].present?
    scope = scope.where(city: params[:city]) if params[:city].present?
    scope = scope.where(country: params[:country]) if params[:country].present?
    scope
  end

  def segment_counts_for(scope)
    Business::SEGMENTS.keys.index_with { |segment| scope.for_segment(segment).count }
  end

  def segment_unread_counts_for(scope)
    Business::SEGMENTS.keys.index_with do |segment|
      Message.inbound.unread.where(business_id: scope.for_segment(segment).select(:id)).count
    end
  end

  def work_status_counts_for(scope)
    Business::WORK_STATUSES.keys.index_with { |status| scope.with_work_status(status).count }
  end

  def employee_tab_counts
    counts = Business.where.not(assigned_to_id: nil).group(:assigned_to_id).count
    @assignee_options.index_with { |employee| counts.fetch(employee.id, 0) }
  end

  def resolve_employee_tab(employee_id)
    return nil if employee_id.blank?

    User.role_employee.find_by(id: employee_id)
  end
end
