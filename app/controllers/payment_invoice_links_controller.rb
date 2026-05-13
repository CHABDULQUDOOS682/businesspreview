class PaymentInvoiceLinksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_unread_message_count

  layout "public"

  def show
    @payment_invoice = PaymentInvoice.find_by!(payment_token: params[:token])

    target_url = @payment_invoice.safe_hosted_invoice_url

    if @payment_invoice.payment_link_expired? || target_url.blank?
      render :expired, status: :gone
      return
    end

    @payment_invoice.mark_opened!

    redirect_to target_url, allow_other_host: true
  end
end
