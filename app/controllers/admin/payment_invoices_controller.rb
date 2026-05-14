class Admin::PaymentInvoicesController < ApplicationController
  layout "admin"

  before_action :require_invoice_access!
  before_action :set_business

  def create
    @payment_invoice = PaymentInvoice.build_for_business(@business)

    # Allow overriding delivery method from params
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

    redirect_to admin_root_path, alert: "You do not have access to create invoices."
  end

  def set_business
    @business = Business.find(params[:business_id])
  end
end
