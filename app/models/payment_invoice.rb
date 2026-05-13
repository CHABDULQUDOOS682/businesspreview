class PaymentInvoice < ApplicationRecord
  belongs_to :business
  has_secure_token :payment_token

  KINDS = {
    "one_time" => "Website Sale",
    "subscription" => "Subscription"
  }.freeze

  DELIVERY_METHODS = {
    "email" => "Email",
    "sms" => "SMS",
    "email_and_sms" => "Email and SMS"
  }.freeze

  STATUSES = %w[draft invoice_sent opened paid expired void uncollectible failed open].freeze
  BILLING_INTERVALS = %w[day week month year].freeze
  DEFAULT_DAYS_UNTIL_DUE = 7
  DEFAULT_BILLING_INTERVAL = "month".freeze

  validates :kind, inclusion: { in: KINDS.keys }
  validates :delivery_method, inclusion: { in: DELIVERY_METHODS.keys }
  validates :status, inclusion: { in: STATUSES }
  validates :billing_interval, inclusion: { in: BILLING_INTERVALS }
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true, length: { is: 3 }
  validates :days_until_due, numericality: { only_integer: true, greater_than: 0 }
  validate :business_has_requested_destination

  before_validation :normalize_currency

  scope :recent, -> { order(created_at: :desc) }

  def self.build_for_business(business)
    kind = business.subscription_active? ? "subscription" : "one_time"

    business.payment_invoices.new(
      kind: kind,
      amount_cents: default_amount_for(business, kind).to_i,
      currency: "usd",
      delivery_method: default_delivery_method_for(business),
      days_until_due: DEFAULT_DAYS_UNTIL_DUE,
      billing_interval: DEFAULT_BILLING_INTERVAL
    )
  end

  def self.default_amount_for(business, kind)
    amount =
      if kind.to_s == "subscription"
        business.subscription_fee
      else
        business.sold_price
      end

    return nil if amount.blank?

    (BigDecimal(amount.to_s) * 100).round.to_i
  end

  def self.default_delivery_method_for(business)
    return "email_and_sms" if business.email.present? && business.phone.present?
    return "email" if business.email.present?

    "sms"
  end

  def kind_label
    KINDS.fetch(kind, kind.to_s.humanize)
  end

  def delivery_method_label
    DELIVERY_METHODS.fetch(delivery_method, delivery_method.to_s.humanize)
  end

  def status_label
    return "Invoice Sent" if status == "invoice_sent"

    status.to_s.titleize
  end

  def email_delivery?
    delivery_method.in?(%w[email email_and_sms])
  end

  def sms_delivery?
    delivery_method.in?(%w[sms email_and_sms])
  end

  def amount
    amount_cents.to_d / 100
  end

  def payment_link_expired?
    paid? || expired?
  end

  def paid?
    status == "paid"
  end

  def expired?
    status == "expired"
  end

  def mark_opened!
    return if payment_link_expired?
    return if status == "opened"

    update!(status: "opened", opened_at: Time.current)
  end

  def store_paid_documents!(stripe_invoice:, receipt_url: nil)
    update!(
      invoice_snapshot_html: build_invoice_snapshot(stripe_invoice),
      receipt_snapshot_html: build_receipt_snapshot(stripe_invoice, receipt_url),
      receipt_url: receipt_url.presence || self.receipt_url
    )
  end

  def safe_stripe_url?
    return false if hosted_invoice_url.blank?

    uri = URI.parse(hosted_invoice_url)

    uri.scheme == "https" &&
      uri.host == "invoice.stripe.com"
  rescue URI::InvalidURIError
    false
  end

  private

  def normalize_currency
    self.currency = currency.to_s.downcase.presence || "usd"
  end

  def business_has_requested_destination
    return if business.blank?

    if email_delivery? && business.email.blank?
      errors.add(:delivery_method, "requires a business email")
    end

    if sms_delivery? && business.phone.blank?
      errors.add(:delivery_method, "requires a business phone number")
    end
  end

  def build_invoice_snapshot(stripe_invoice)
    <<~HTML
      <h1>Invoice #{stripe_value(stripe_invoice, :id) || stripe_invoice_id}</h1>
      <p>Status: #{stripe_value(stripe_invoice, :status) || status}</p>
      <p>Business: #{business.name}</p>
      <p>Amount due: #{format_amount(stripe_value(stripe_invoice, :amount_due) || amount_cents)}</p>
      <p>Amount paid: #{format_amount(stripe_value(stripe_invoice, :amount_paid) || amount_cents)}</p>
      <p>Hosted invoice: #{stripe_value(stripe_invoice, :hosted_invoice_url) || hosted_invoice_url}</p>
      <p>Invoice PDF: #{stripe_value(stripe_invoice, :invoice_pdf) || invoice_pdf}</p>
      <p>Saved at: #{Time.current.iso8601}</p>
    HTML
  end

  def build_receipt_snapshot(stripe_invoice, receipt_url)
    <<~HTML
      <h1>Receipt for Invoice #{stripe_value(stripe_invoice, :id) || stripe_invoice_id}</h1>
      <p>Status: #{stripe_value(stripe_invoice, :status) || status}</p>
      <p>Business: #{business.name}</p>
      <p>Amount paid: #{format_amount(stripe_value(stripe_invoice, :amount_paid) || amount_cents)}</p>
      <p>Paid at: #{paid_at&.iso8601 || Time.current.iso8601}</p>
      <p>Stripe receipt: #{receipt_url}</p>
    HTML
  end

  def stripe_value(object, key)
    return if object.blank?
    return object.public_send(key) if object.respond_to?(key)

    object[key.to_s] || object[key.to_sym]
  end

  def format_amount(cents)
    amount = cents.to_i.to_d / 100
    "#{currency.upcase} #{format('%.2f', amount)}"
  end
end
