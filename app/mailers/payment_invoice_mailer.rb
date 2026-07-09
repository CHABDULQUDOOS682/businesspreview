class PaymentInvoiceMailer < ApplicationMailer
  def invoice_link
    @payment_invoice = params[:payment_invoice]
    @business = @payment_invoice.business
    @payment_url = payment_invoice_link_url(
      @payment_invoice.payment_token,
      host: ENV.fetch("APP_HOST", "localhost"),
      protocol: ENV.fetch("APP_PROTOCOL", "https")
    )

    mail(
      to: @business.email,
      subject: "#{@payment_invoice.kind_label} invoice for #{@business.name}"
    )
  end

  def due_soon_followup
    @payment_invoice = params[:payment_invoice]
    @business = @payment_invoice.business
    @payment_url = payment_invoice_link_url(
      @payment_invoice.payment_token,
      host: ENV.fetch("APP_HOST", "localhost"),
      protocol: ENV.fetch("APP_PROTOCOL", "https")
    )

    mail(
      to: @business.email,
      subject: "Reminder: invoice due tomorrow for #{@business.name}"
    )
  end

  def subscription_overdue_reminder
    @payment_invoice = params[:payment_invoice]
    @business = @payment_invoice.business
    @reminder_number = params[:reminder_number]
    @payment_url = payment_invoice_link_url(
      @payment_invoice.payment_token,
      host: ENV.fetch("APP_HOST", "localhost"),
      protocol: ENV.fetch("APP_PROTOCOL", "https")
    )

    mail(
      to: @business.email,
      subject: "Overdue subscription payment for #{@business.name}"
    )
  end
end
