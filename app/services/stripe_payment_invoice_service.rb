require "stripe"

class StripePaymentInvoiceService
  class ConfigurationError < StandardError; end

  DEFAULT_PRODUCT_NAMES = {
    "one_time" => "Website Sale",
    "subscription" => "Website Subscription"
  }.freeze

  attr_reader :payment_invoice

  def initialize(payment_invoice)
    @payment_invoice = payment_invoice
  end

  def create_and_send!
    ensure_configured!

    payment_invoice.update!(status: "draft", last_error: nil)

    if payment_invoice.kind == "subscription"
      create_subscription_invoice!
    else
      create_one_time_invoice!
    end

    send_email! if payment_invoice.email_delivery?
    send_sms! if payment_invoice.sms_delivery?
    schedule_followup_email!
    payment_invoice
  rescue ::Stripe::StripeError, ConfigurationError => e
    payment_invoice.update(status: "failed", last_error: e.message)
    raise
  end

  private

  def ensure_configured!
    raise ConfigurationError, "STRIPE_SECRET_KEY is not configured" if ::Stripe.api_key.blank?
  end

  def create_one_time_invoice!
    customer_id = ensure_customer!
    invoice = ::Stripe::Invoice.create(
      customer: customer_id,
      collection_method: "send_invoice",
      days_until_due: payment_invoice.days_until_due,
      metadata: stripe_metadata
    )

    ::Stripe::InvoiceItem.create(
      customer: customer_id,
      invoice: invoice.id,
      amount: payment_invoice.amount_cents,
      currency: payment_invoice.currency,
      description: payment_invoice.kind_label,
      metadata: stripe_metadata
    )

    finalized_invoice = ::Stripe::Invoice.finalize_invoice(invoice.id)
    update_from_stripe_invoice!(finalized_invoice)
  end

  def create_subscription_invoice!
    customer_id = ensure_customer!
    product = ::Stripe::Product.create(
      name: "#{payment_invoice.business.name} #{DEFAULT_PRODUCT_NAMES.fetch(payment_invoice.kind)}",
      metadata: stripe_metadata
    )
    price = ::Stripe::Price.create(
      product: product.id,
      unit_amount: payment_invoice.amount_cents,
      currency: payment_invoice.currency,
      recurring: { interval: payment_invoice.billing_interval },
      metadata: stripe_metadata
    )

    subscription = ::Stripe::Subscription.create(
      customer: customer_id,
      items: [ { price: price.id } ],
      collection_method: "send_invoice",
      days_until_due: payment_invoice.days_until_due,
      metadata: stripe_metadata,
      expand: [ "latest_invoice" ]
    )

    latest_invoice = stripe_object_value(subscription, :latest_invoice)
    latest_invoice = ::Stripe::Invoice.retrieve(latest_invoice) if latest_invoice.is_a?(String)

    sent_invoice = latest_invoice
    if latest_invoice.present? && stripe_object_value(latest_invoice, :status) == "draft"
      sent_invoice = ::Stripe::Invoice.finalize_invoice(latest_invoice.id)
    end

    payment_invoice.update!(
      stripe_subscription_id: subscription.id,
      stripe_product_id: product.id,
      stripe_price_id: price.id
    )
    update_from_stripe_invoice!(sent_invoice) if sent_invoice.present?
  end

  def ensure_customer!
    return payment_invoice.business.stripe_customer_id if payment_invoice.business.stripe_customer_id.present?

    customer = ::Stripe::Customer.create(
      email: payment_invoice.business.email.presence,
      phone: payment_invoice.business.phone.presence,
      name: payment_invoice.business.owner_name.presence || payment_invoice.business.name,
      description: "Business ##{payment_invoice.business.id}: #{payment_invoice.business.name}",
      metadata: {
        business_id: payment_invoice.business.id,
        business_name: payment_invoice.business.name
      }
    )

    payment_invoice.business.update!(stripe_customer_id: customer.id)
    customer.id
  end

  def update_from_stripe_invoice!(invoice)
    payment_invoice.update!(
      status: stripe_object_value(invoice, :status) == "paid" ? "paid" : "invoice_sent",
      stripe_customer_id: stripe_object_value(invoice, :customer),
      stripe_invoice_id: stripe_object_value(invoice, :id),
      hosted_invoice_url: stripe_object_value(invoice, :hosted_invoice_url),
      invoice_pdf: stripe_object_value(invoice, :invoice_pdf),
      sent_to_email: payment_invoice.email_delivery? ? payment_invoice.business.email : nil,
      sent_to_phone: payment_invoice.sms_delivery? ? payment_invoice.business.phone : nil,
      sent_at: Time.current,
      paid_at: stripe_object_value(invoice, :status) == "paid" ? Time.current : payment_invoice.paid_at
    )
  end

  def send_sms!
    raise ConfigurationError, "Stripe did not return a hosted invoice URL" if payment_invoice.hosted_invoice_url.blank?

    SmsService.send_sms(
      to: payment_invoice.business.phone,
      message: sms_message
    )

    Message.create!(
      from_number: ENV["TWILIO_PHONE_NUMBER"],
      to_number: payment_invoice.business.phone,
      body: sms_message,
      direction: "outbound",
      business: payment_invoice.business
    )
  end

  def send_email!
    raise ConfigurationError, "Stripe did not return a hosted invoice URL" if payment_invoice.hosted_invoice_url.blank?

    PaymentInvoiceMailer.with(payment_invoice: payment_invoice).invoice_link.deliver_now
  end

  def schedule_followup_email!
    return unless payment_invoice.email_delivery?
    return if payment_invoice.business.email.blank?

    PaymentInvoiceFollowupJob.set(wait_until: payment_invoice.sent_at + 6.days).perform_later(payment_invoice)
  end

  def sms_message
    [
      "Hi #{payment_invoice.business.owner_name.presence || payment_invoice.business.name},",
      "your #{payment_invoice.kind_label.downcase} invoice is ready:",
      payment_url
    ].join(" ")
  end

  def payment_url
    url_options = Rails.application.config.action_mailer.default_url_options.compact
    Rails.application.routes.url_helpers.payment_invoice_link_url(payment_invoice.payment_token, **url_options)
  end

  def stripe_metadata
    {
      payment_invoice_id: payment_invoice.id,
      business_id: payment_invoice.business_id,
      kind: payment_invoice.kind
    }
  end

  def stripe_object_value(object, key)
    return if object.blank?
    return object.public_send(key) if object.respond_to?(key)

    object[key.to_s] || object[key.to_sym]
  end
end
