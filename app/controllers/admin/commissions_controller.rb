class Admin::CommissionsController < ApplicationController
  layout "admin"
  before_action :set_commission, only: [ :approve, :mark_paid_out ]
  before_action :require_commission_management_access!, only: [ :approve, :mark_paid_out ]

  def index
    base_scope = Commission.includes(:user, :business, :payment_invoice, :approved_by)
    base_scope = base_scope.for_employee(current_user) if employee_role?

    @employee_summaries = build_employee_summaries(base_scope)

    scope = base_scope.order(created_at: :desc)
    if (super_admin? || admin_role?) && params[:employee_id].present?
      @selected_employee = User.find_by(id: params[:employee_id])
      scope = scope.for_employee(@selected_employee) if @selected_employee.present?
    end

    @commissions = scope
    @pending_total = scope.select { |commission| commission.status == "pending" }.sum(&:commission_amount)
    @approved_total = scope.select { |commission| commission.status == "approved" }.sum(&:commission_amount)
    @paid_out_total = scope.select { |commission| commission.status == "paid_out" }.sum(&:commission_amount)
    @current_month_total = scope.select do |commission|
      commission.payment_invoice&.paid_at&.between?(Time.current.beginning_of_month, Time.current.end_of_month)
    end.sum(&:commission_amount)
  end

  def approve
    @commission.approve!(current_user, percentage_override: params[:percentage])
    redirect_to admin_commissions_path, notice: "Commission approved."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_commissions_path, alert: e.record.errors.full_messages.to_sentence.presence || e.message
  end

  def mark_paid_out
    @commission.mark_paid_out!
    redirect_to admin_commissions_path, notice: "Commission marked as paid out."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_commissions_path, alert: e.record.errors.full_messages.to_sentence.presence || e.message
  end

  private

  def set_commission
    @commission = Commission.find(params[:id])
  end

  def require_commission_management_access!
    return if super_admin? || admin_role?

    redirect_to admin_commissions_path, alert: "You do not have access to manage commissions."
  end

  def build_employee_summaries(scope)
    scope.group_by(&:user).map do |user, commissions|
      {
        user: user,
        pending: commissions.select { |commission| commission.status == "pending" }.sum(&:commission_amount),
        approved: commissions.select { |commission| commission.status == "approved" }.sum(&:commission_amount),
        paid_out: commissions.select { |commission| commission.status == "paid_out" }.sum(&:commission_amount),
        total: commissions.sum(&:commission_amount),
        count: commissions.size
      }
    end.sort_by { |summary| [-summary[:total].to_d, summary[:user].display_name.to_s.downcase] }
  end
end
