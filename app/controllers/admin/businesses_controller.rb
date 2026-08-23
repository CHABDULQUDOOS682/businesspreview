class Admin::BusinessesController < ApplicationController
  layout "admin"
  before_action :require_super_admin!, only: [ :import, :verify_phone ]
  before_action :require_admin_or_super_admin!, only: [ :send_review_link, :assign ]
  before_action :set_seller_options, only: [ :new, :create, :edit, :update ]
  before_action :set_business, only: [ :show, :edit, :update, :send_review_link, :update_work_status ]
  before_action :authorize_business_access!, only: [ :show, :edit, :update, :update_work_status ]

  def index
    @assignee_options = User.role_employee.order(:name, :email) unless employee_role?
    @work_status = Business.normalize_work_status(params[:work_status])

    if employee_role?
      index_for_employee
    else
      index_for_admin
    end
  end

  def assign
    business_ids = Array(params[:business_ids]).map(&:presence).compact
    if business_ids.blank?
      redirect_to admin_businesses_path(segment: params[:segment].presence, employee_id: params[:employee_id].presence),
                  alert: "Select at least one business to assign."
      return
    end

    assignee = resolve_assignee(params[:assigned_to_id])
    if params[:assigned_to_id].present? && assignee.nil?
      redirect_to admin_businesses_path(segment: params[:segment].presence), alert: "Choose a valid employee."
      return
    end

    now = Time.current
    attrs =
      if assignee
        { assigned_to_id: assignee.id, assigned_at: now, work_status: "assigned", updated_at: now }
      else
        { assigned_to_id: nil, assigned_at: nil, work_status: nil, updated_at: now }
      end

    updated = Business.where(id: business_ids).update_all(attrs)

    notice =
      if assignee
        "Assigned #{updated} #{"business".pluralize(updated)} to #{assignee.display_name}."
      else
        "Unassigned #{updated} #{"business".pluralize(updated)}."
      end

    redirect_to admin_businesses_path(segment: params[:segment].presence, employee_id: params[:employee_id].presence), notice: notice
  end

  def update_work_status
    status = Business.normalize_work_status(params[:work_status])
    if status.blank?
      redirect_to admin_business_path(@business), alert: "Choose a valid status."
      return
    end

    attrs = { work_status: status }
    attrs[:employee_report] = params[:employee_report] if params.key?(:employee_report)
    attrs[:completion_notes] = params[:completion_notes] if params.key?(:completion_notes)

    if @business.update(attrs)
      redirect_to admin_business_path(@business), notice: "Status updated to #{@business.work_status_label}."
    else
      redirect_to admin_business_path(@business), alert: @business.errors.full_messages.to_sentence
    end
  end

  def import
    unless params[:file].present?
      redirect_to admin_businesses_path, alert: "Please upload a CSV file."
      return
    end

    begin
      import = BusinessImportService.new(params[:file].path, imported_by: current_user).call
    rescue => e
      redirect_to admin_businesses_path, alert: "Import failed: #{e.message}"
      return
    end

    redirect_to admin_business_import_path(import),
                notice: "Imported #{import.created_count} of #{import.total_rows} rows " \
                        "(#{import.duplicate_count} duplicates, #{import.failed_count} failed)."
  end

  def new
    @business = Business.new
  end

  def create
    @business = Business.new(business_params)

    if @business.save
      redirect_to admin_businesses_path, notice: "Business created!"
    else
      flash.now[:alert] = @business.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @payment_invoice = PaymentInvoice.build_for_business(@business)
    @payment_invoices = @business.payment_invoices.recent
    @contracts = @business.contracts.recent if super_admin? || admin_role?
  end

  def edit
  end

  def update
    previous_configured = Crm::WebhookClient.new(@business).configured?

    if @business.update(business_params)
      @business.activate_subscription_billing! if @business.subscription_active? && @business.sold_price_collected? && @business.next_subscription_invoice_at.blank?

      newly_configured = !previous_configured && Crm::WebhookClient.new(@business.reload).configured?
      connection_touched = @business.saved_change_to_site_api_base_url? ||
        @business.saved_change_to_site_api_secret? ||
        @business.saved_change_to_business_number?

      if Crm::WebhookClient.new(@business).configured? && (newly_configured || connection_touched)
        Crm::SyncBusinessContractsJob.perform_later(@business.id)
      end

      redirect_to admin_business_path(@business), notice: employee_role? ? "Business email updated!" : "Business updated!"
    else
      flash.now[:alert] = @business.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def send_review_link
    method = params[:delivery_method] # 'email' or 'sms'
    link = @business.review_url

    message = "Hi #{@business.owner_name || @business.name}, we'd love to hear your feedback! Please leave us a review here: #{link}"

    case method
    when "sms"
      if @business.phone.present?
        SmsService.send_sms(to: @business.phone, message: message)
        Message.create!(
          from_number: ENV["TWILIO_PHONE_NUMBER"],
          to_number: @business.phone,
          body: message,
          direction: "outbound",
          business_id: @business.id
        )
        redirect_to admin_business_path(@business), notice: "Review link sent via SMS."
      else
        redirect_to admin_business_path(@business), alert: "Business phone missing."
      end
    when "email"
      if @business.email.present?
        ReviewMailer.send_link(@business).deliver_later
        redirect_to admin_business_path(@business), notice: "Review link sent via Email."
      else
        redirect_to admin_business_path(@business), alert: "Business email missing."
      end
    else
      redirect_to admin_business_path(@business), alert: "Invalid delivery method."
    end
  end

  def verify_phone
    business = Business.find(params[:id])
    PhoneLookupJob.perform_later(business.id)
    redirect_to admin_business_path(business), notice: "Number verification queued."
  end

  private

  def index_for_employee
    @segment = "nurture"
    base_scope = Business.assigned_to_user(current_user)
    @work_status_counts = work_status_counts_for(base_scope)
    @work_status ||= "assigned"

    scoped = base_scope.with_work_status(@work_status)
    @pagy, @businesses = pagy(apply_filters(scoped).order(created_at: :desc))

    @niches = base_scope.where.not(niche: [ nil, "" ]).distinct.pluck(:niche).sort
    @cities = base_scope.where.not(city: [ nil, "" ]).distinct.pluck(:city).sort
    @countries = base_scope.where.not(country: [ nil, "" ]).distinct.pluck(:country).sort
  end

  def index_for_admin
    @segment = Business.normalize_segment(params[:segment])
    @employee_tab = resolve_employee_tab(params[:employee_id])
    base_scope = Business.all
    base_scope = base_scope.assigned_to_user(@employee_tab) if @employee_tab

    segment_scope = base_scope.for_segment(@segment)
    @segment_counts = segment_counts_for(@employee_tab ? Business.assigned_to_user(@employee_tab) : Business.all)
    @segment_unread_counts = segment_unread_counts_for(@employee_tab ? Business.assigned_to_user(@employee_tab) : Business.all)
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

  def set_business
    @business = Business.find(params[:id])
  end

  def authorize_business_access!
    return unless employee_role?
    return if @business.assigned_to_id == current_user.id

    redirect_to admin_businesses_path, alert: "You do not have access to that business."
  end

  def apply_filters(scope)
    scope = scope.where("LOWER(name) ILIKE LOWER(?)", "%#{params[:name]}%") if params[:name].present?
    scope = scope.where(niche: params[:niche]) if params[:niche].present?
    scope = scope.where(city: params[:city]) if params[:city].present?
    scope = scope.where(country: params[:country]) if params[:country].present?

    unless employee_role?
      case params[:assigned_to_id]
      when "unassigned"
        scope = scope.unassigned
      when nil, ""
        # no filter
      else
        scope = scope.where(assigned_to_id: params[:assigned_to_id])
      end
    end

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

  def resolve_assignee(assigned_to_id)
    return nil if assigned_to_id.blank?

    User.role_employee.find_by(id: assigned_to_id)
  end

  def business_params
    if employee_role?
      return params.require(:business).permit(:email)
    end

    permitted = params.require(:business)
                      .permit(
                        :name,
                        :owner_name,
                        :city,
                        :country,
                        :business_location,
                        :niche,
                        :phone,
                        :email,
                        :website_url,
                        :website_name,
                        :rating,
                        :message,
                        :sold_price,
                        :subscription_fee,
                        :subscription,
                        :sold_by_id,
                        :assigned_to_id,
                        :business_number,
                        :site_api_base_url,
                        :site_api_secret,
                        :site_external_id
                      )

    permitted[:sold_by_id] = nil if permitted[:sold_by_id].blank?
    permitted[:assigned_to_id] = nil if permitted[:assigned_to_id].blank?
    permitted
  end

  def set_seller_options
    sellers = User.where(role: "employee").to_a
    sellers << current_user if current_user&.role_admin? || current_user&.role_super_admin?
    @seller_options = sellers.uniq.sort_by { |user| user.display_name.to_s.downcase }
    @assignee_options = User.role_employee.order(:name, :email)
  end
end
