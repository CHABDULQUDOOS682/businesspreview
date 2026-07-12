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
      stripe_invoice = event.data.object
      if stripe_value(stripe_invoice, :status).to_s == "paid"
        update_paid_invoice(stripe_invoice)
      else
        update_invoice(stripe_invoice)
      end
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

    if payment_invoice.kind == "subscription" && !payment_invoice.paid?
      Billing::InvoiceLifecycleService.new(payment_invoice).handle_unpaid_state!(status: new_status)
    end
  end

  def update_paid_invoice(stripe_invoice)
    payment_invoice = find_or_build_payment_invoice(stripe_invoice)
    if payment_invoice.blank?
      Rails.logger.warn(
        "[StripeWebhooks] paid event for #{stripe_value(stripe_invoice, :id)} " \
        "could not be matched to a local PaymentInvoice " \
        "(metadata business_id=#{stripe_metadata_value(stripe_invoice, :business_id).inspect} " \
        "payment_invoice_id=#{stripe_metadata_value(stripe_invoice, :payment_invoice_id).inspect})"
      )
      return
    end

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
    Billing::InvoiceLifecycleService.new(payment_invoice).handle_paid!(paid_at: payment_invoice.paid_at)
  end

  def find_or_build_payment_invoice(stripe_invoice)
    stripe_id = stripe_value(stripe_invoice, :id)
    payment_invoice = PaymentInvoice.find_by(stripe_invoice_id: stripe_id)
    return payment_invoice if payment_invoice.present?

    payment_invoice_id = stripe_metadata_value(stripe_invoice, :payment_invoice_id)
    if payment_invoice_id.present?
      by_id = PaymentInvoice.find_by(id: payment_invoice_id)
      if by_id
        by_id.update!(stripe_invoice_id: stripe_id) if by_id.stripe_invoice_id.blank?
        return by_id
      end
    end

    business_id = stripe_metadata_value(stripe_invoice, :business_id)
    return nil if business_id.blank?

    business = Business.find_by(id: business_id)
    return nil if business.blank?

    PaymentInvoice.find_by(stripe_invoice_id: stripe_id, business_id: business.id)
  end

  def stripe_metadata_value(stripe_invoice, key)
    metadata = stripe_value(stripe_invoice, :metadata)
    return nil if metadata.blank?

    metadata[key.to_s] || metadata[key.to_sym]
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
