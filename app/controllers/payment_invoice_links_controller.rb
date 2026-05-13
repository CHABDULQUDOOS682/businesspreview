class PaymentInvoiceLinksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_unread_message_count

  layout "public"

  def show
    @payment_invoice = PaymentInvoice.find_by!(payment_token: params[:token])

    if @payment_invoice.payment_link_expired? ||
       !@payment_invoice.safe_stripe_url?
      render :expired, status: :gone
      return
    end

    @payment_invoice.mark_opened!

    redirect_to(
      @payment_invoice.hosted_invoice_url,
      allow_other_host: true
    )
  end
end
