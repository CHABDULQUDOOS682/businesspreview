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

    new_status = attrs[:status].presence || mapped_invoice_status(stripe_invoice.status, payment_invoice.status)
    new_url = stripe_value(stripe_invoice, :hosted_invoice_url).presence || payment_invoice.hosted_invoice_url

    payment_invoice.update!(
      {
        status: new_status,
        hosted_invoice_url: new_url,
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
    return nil if stripe_invoice.blank?
    # The 'payment_intent' attribute was removed in newer Stripe API versions.
    # We now need to list payment intents associated with this invoice.
    begin
      payment_intents = ::Stripe::PaymentIntent.list(
        invoice: stripe_invoice.id,
        limit: 1,
        expand: [ "data.latest_charge" ]
      )

      payment_intent = payment_intents.data.first
      return nil if payment_intent.blank?

      charge = stripe_value(payment_intent, :latest_charge)
      url = stripe_value(charge, :receipt_url)
      url
    rescue ::Stripe::StripeError => e
      nil
    end
  end

  def mapped_invoice_status(stripe_status, current_status)
    return "paid" if stripe_status == "paid"
    return "invoice_sent" if stripe_status == "open" && current_status != "opened"

    current_status
  end

  def stripe_value(object, key)
    return nil if object.blank?

    # Try hash access first as it's more reliable for Stripe objects
    value = object[key.to_s] || object[key.to_sym]
    return value if value.present?

    # Fallback to public_send if hash access fails
    if object.respond_to?(key)
      begin
        object.public_send(key)
      rescue KeyError
        nil
      end
    else
      nil
    end
  end
end
