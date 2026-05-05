class PaymentInvoiceMailer < ApplicationMailer
  def invoice_link
    @payment_invoice = params[:payment_invoice]
    @business = @payment_invoice.business
    @payment_url = payment_invoice_link_url(@payment_invoice.payment_token)

    mail(
      to: @business.email,
      subject: "#{@payment_invoice.kind_label} invoice for #{@business.name}"
    )
  end

  def due_soon_followup
    @payment_invoice = params[:payment_invoice]
    @business = @payment_invoice.business
    @payment_url = payment_invoice_link_url(@payment_invoice.payment_token)

    mail(
      to: @business.email,
      subject: "Reminder: invoice due tomorrow for #{@business.name}"
    )
  end
end
