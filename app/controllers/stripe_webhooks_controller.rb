require "stripe"

class StripeWebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_unread_message_count
  skip_before_action :verify_authenticity_token

  def create
    event = verified_event
    handle_event(event)

    head :ok
  rescue JSON::ParserError, ::Stripe::SignatureVerificationError
    head :bad_request
  end

  private

  def verified_event
    payload = request.body.read
    signature = request.env["HTTP_STRIPE_SIGNATURE"]
    webhook_secret = ENV["STRIPE_WEBHOOK_SECRET"]

    if webhook_secret.present?
      ::Stripe::Webhook.construct_event(payload, signature, webhook_secret)
    else
      ::Stripe::Event.construct_from(JSON.parse(payload))
    end
  end

  def handle_event(event)
    case event.type
    when "invoice.paid", "invoice.payment_succeeded"
      update_paid_invoice(event.data.object)
    when "invoice.payment_failed"
      update_invoice(event.data.object, status: "opened")
    when "invoice.voided"
      update_invoice(event.data.object, status: "void")
    when "invoice.marked_uncollectible"
      update_invoice(event.data.object, status: "uncollectible")
    when "invoice.finalized", "invoice.sent"
      update_invoice(event.data.object, status: "invoice_sent")
    when "invoice.updated"
      update_invoice(event.data.object)
    end
  end

  def update_invoice(stripe_invoice, attrs = {})
    payment_invoice = PaymentInvoice.find_by(stripe_invoice_id: stripe_invoice.id)
    return if payment_invoice.blank?

    payment_invoice.update!(
      {
        status: attrs[:status].presence || mapped_invoice_status(stripe_invoice.status, payment_invoice.status),
        hosted_invoice_url: stripe_value(stripe_invoice, :hosted_invoice_url).presence || payment_invoice.hosted_invoice_url,
        invoice_pdf: stripe_value(stripe_invoice, :invoice_pdf).presence || payment_invoice.invoice_pdf,
        paid_at: attrs[:paid_at].presence || payment_invoice.paid_at
      }.compact
    )
  end

  def update_paid_invoice(stripe_invoice)
    payment_invoice = PaymentInvoice.find_by(stripe_invoice_id: stripe_invoice.id)
    return if payment_invoice.blank?

    full_invoice = retrieve_invoice_for_receipt(stripe_invoice)
    receipt_url = receipt_url_for(full_invoice)

    payment_invoice.update!(
      status: "paid",
      hosted_invoice_url: stripe_value(full_invoice, :hosted_invoice_url).presence || payment_invoice.hosted_invoice_url,
      invoice_pdf: stripe_value(full_invoice, :invoice_pdf).presence || payment_invoice.invoice_pdf,
      paid_at: Time.current,
      receipt_url: receipt_url
    )
    payment_invoice.store_paid_documents!(stripe_invoice: full_invoice, receipt_url: receipt_url)
  end

  def retrieve_invoice_for_receipt(stripe_invoice)
    ::Stripe::Invoice.retrieve(
      id: stripe_invoice.id,
      expand: [ "payment_intent.latest_charge" ]
    )
  rescue ::Stripe::StripeError
    stripe_invoice
  end

  def receipt_url_for(stripe_invoice)
    payment_intent = stripe_value(stripe_invoice, :payment_intent)
    charge = stripe_value(payment_intent, :latest_charge)

    stripe_value(charge, :receipt_url)
  end

  def mapped_invoice_status(stripe_status, current_status)
    return "paid" if stripe_status == "paid"
    return "invoice_sent" if stripe_status == "open" && current_status != "opened"

    current_status
  end

  def stripe_value(object, key)
    return if object.blank?
    return object.public_send(key) if object.respond_to?(key)

    object[key.to_s] || object[key.to_sym]
  end
end
