class PaymentInvoiceLinksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_unread_message_count

  layout "public"

  def show
    @payment_invoice = PaymentInvoice.find_by!(payment_token: params[:token])
    target_url = @payment_invoice.hosted_invoice_url

    if @payment_invoice.payment_link_expired? || target_url.blank?
      render :expired, status: :gone
      return
    end

    uri = URI.parse(target_url)
    allowed_hosts = ["invoice.stripe.com"]

    if uri.scheme == "https" && allowed_hosts.include?(uri.host)
      @payment_invoice.mark_opened!
      redirect_to target_url, allow_other_host: true
    else
      render plain: "Unauthorized destination", status: :bad_request
    end
  end
end
