class Admin::BusinessesController < ApplicationController
  layout "admin"
  before_action :require_super_admin!, only: [ :import ]
  before_action :set_seller_options, only: [ :new, :create, :edit, :update ]

  def index
    @segment = employee_role? ? "nurture" : Business.normalize_segment(params[:segment])
    @segment_counts = Business.segment_counts

    segment_scope = Business.for_segment(@segment)
    @pagy, @businesses = pagy(apply_filters(segment_scope).order(created_at: :desc))

    @niches = segment_scope.where.not(niche: [ nil, "" ]).distinct.pluck(:niche).sort
    @cities = segment_scope.where.not(city: [ nil, "" ]).distinct.pluck(:city).sort
    @countries = segment_scope.where.not(country: [ nil, "" ]).distinct.pluck(:country).sort
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
    @business.sold_by ||= current_user if @seller_options.include?(current_user)
  end

  def create
    @business = Business.new(business_params)
    @business.sold_by ||= current_user if @seller_options.include?(current_user)

    if @business.save
      redirect_to admin_businesses_path, notice: "Business created!"
    else
      render :new
    end
  end

  def show
    @business = Business.find(params[:id])
    @payment_invoice = PaymentInvoice.build_for_business(@business)
    @payment_invoices = @business.payment_invoices.recent
  end

  def edit
    @business = Business.find(params[:id])
  end

  def update
    @business = Business.find(params[:id])
    if @business.update(business_params)
      redirect_to admin_business_path(@business), notice: "Business updated!"
    else
      render :edit, alert: "Update failed."
    end
  end

  def send_review_link
    @business = Business.find(params[:id])
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

  private

  def apply_filters(scope)
    scope = scope.where("LOWER(name) ILIKE LOWER(?)", "%#{params[:name]}%") if params[:name].present?
    scope = scope.where(niche: params[:niche]) if params[:niche].present?
    scope = scope.where(city: params[:city]) if params[:city].present?
    scope = scope.where(country: params[:country]) if params[:country].present?
    scope
  end

  def business_params
    params.require(:business)
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
            :task_source_enabled,
            :task_base_url,
            :task_secret,
            :task_endpoint_path
          )
  end

  def set_seller_options
    sellers = User.where(role: "employee").to_a
    sellers << current_user if current_user&.role_admin? || current_user&.role_super_admin?
    @seller_options = sellers.uniq.sort_by { |user| user.display_name.to_s.downcase }
  end
end
