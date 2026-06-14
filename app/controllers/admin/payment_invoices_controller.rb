class Admin::PaymentInvoicesController < ApplicationController
  layout "admin"

  before_action :require_invoice_access!
  before_action :set_business, only: [ :create ]

  def index
    scope = PaymentInvoice.includes(:business).recent

    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(kind: params[:kind]) if params[:kind].present?
    if params[:q].present?
      q = "%#{params[:q]}%"
      scope = scope.joins(:business).where("businesses.name ILIKE :q OR businesses.email ILIKE :q", q: q)
    end

    @pagy, @invoices = pagy(scope, limit: 25)
    @total_paid = PaymentInvoice.where(status: "paid").sum(:amount_cents).to_d / 100
    @total_pending = PaymentInvoice.where(status: %w[invoice_sent opened]).sum(:amount_cents).to_d / 100
    @total_count = PaymentInvoice.count
  end

  def create
    @payment_invoice = PaymentInvoice.build_for_business(@business)

    if params[:payment_invoice] && params[:payment_invoice][:delivery_method]
      @payment_invoice.delivery_method = params[:payment_invoice][:delivery_method]
    end

    if @payment_invoice.save
      StripePaymentInvoiceService.new(@payment_invoice).create_and_send!
      redirect_to admin_business_path(@business), notice: "Invoice created and sent via #{@payment_invoice.delivery_method_label}."
    else
      redirect_to admin_business_path(@business), alert: @payment_invoice.errors.full_messages.to_sentence
    end
  rescue StripePaymentInvoiceService::ConfigurationError => e
    redirect_to admin_business_path(@business), alert: "Invoice could not be sent: #{e.message}"
  rescue StandardError => e
    redirect_to admin_business_path(@business), alert: "Invoice could not be sent: #{e.message}"
  end

  private

  def require_invoice_access!
    return if super_admin? || admin_role?
    redirect_to admin_root_path, alert: "You do not have access to invoices."
  end

  def set_business
    @business = Business.find(params[:business_id])
  end
end
