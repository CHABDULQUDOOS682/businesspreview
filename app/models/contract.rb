# frozen_string_literal: true

require "base64"
require "stringio"

class Contract < ApplicationRecord
  KINDS = {
    "subscription" => "Monthly subscription",
    "one_time_project" => "One-time project"
  }.freeze

  STATUSES = {
    "draft" => "Draft",
    "sent" => "Awaiting signature",
    "signed" => "Signed",
    "void" => "Void"
  }.freeze

  belongs_to :business
  belongs_to :created_by, class_name: "User"
  has_one_attached :document
  has_one_attached :client_signature

  has_secure_token :access_token

  validates :kind, inclusion: { in: KINDS.keys }
  validates :status, inclusion: { in: STATUSES.keys }
  validates :title, :client_name, :client_email, :agency_name, presence: true
  validates :scope_of_work, :pricing_terms, :timeline_terms, :termination_terms, presence: true
  validates :client_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :recent, -> { order(created_at: :desc) }

  before_validation :apply_party_defaults, on: :create

  def kind_label
    KINDS[kind] || kind.to_s.humanize
  end

  def package_label
    return nil if package_key.blank?

    Contracts::PackageCatalog.package_label(kind, package_key)
  end

  def status_label
    STATUSES[status] || status.to_s.humanize
  end

  def draft?
    status == "draft"
  end

  def sent?
    status == "sent"
  end

  def signed?
    status == "signed"
  end

  def void?
    status == "void"
  end

  def signable?
    sent? || draft?
  end

  def amount
    return nil if amount_cents.blank?

    amount_cents / 100.0
  end

  def apply_template!(kind_key)
    self.kind = kind_key
    case kind_key
    when "subscription"
      self.title ||= "Website partnership agreement"
      self.scope_of_work = default_subscription_scope
      self.pricing_terms = default_subscription_pricing
      self.timeline_terms = default_subscription_timeline
      self.termination_terms = default_subscription_termination
    when "one_time_project"
      self.title ||= "Website project agreement"
      self.scope_of_work = default_project_scope
      self.pricing_terms = default_project_pricing
      self.timeline_terms = default_project_timeline
      self.termination_terms = default_project_termination
    end
  end

  def mark_sent!
    update!(status: "sent", sent_at: Time.current)
  end

  def mark_void!
    update!(status: "void")
  end

  def sign_by_client!(name:, ip:, user_agent:, signature_data: nil, agency_signer_name: "DevDeBizz")
    raise ArgumentError, "Contract is not signable" unless signable?
    raise ArgumentError, "Drawn signature required" if signature_data.blank?

    attach_client_signature!(signature_data)

    update!(
      status: "signed",
      client_signer_name: name.to_s.strip.presence || client_name.presence || "Client",
      client_signed_at: Time.current,
      client_signer_ip: ip.to_s.truncate(100),
      client_signer_user_agent: user_agent.to_s.truncate(500),
      agency_signer_name: agency_signer_name,
      agency_signed_at: Time.current,
      sent_at: sent_at || Time.current
    )
  end

  private

  def attach_client_signature!(signature_data)
    match = signature_data.to_s.match(/\Adata:image\/png;base64,(.+)\z/m)
    raise ArgumentError, "Invalid signature image" unless match

    decoded = Base64.decode64(match[1])
    raise ArgumentError, "Invalid signature image" if decoded.blank?

    client_signature.attach(
      io: StringIO.new(decoded),
      filename: "client-signature-#{id || SecureRandom.hex(4)}.png",
      content_type: "image/png"
    )
  end

  def apply_party_defaults
    self.agency_name = "DevDeBizz" if agency_name.blank?
    self.currency = "usd" if currency.blank?
    self.status = "draft" if status.blank?
    if business.present?
      self.client_name = business.name if client_name.blank?
      self.client_email = business.email if client_email.blank?
    end
  end

  def default_subscription_scope
    <<~TEXT.strip
      DevDeBizz will provide ongoing website hosting, monitoring, content updates within plan limits, SEO support as described in the selected subscription plan, and email support. Scope excludes new page builds beyond plan limits, custom application development, and third-party fees unless agreed in writing.
    TEXT
  end

  def default_subscription_pricing
    <<~TEXT.strip
      Client pays the agreed one-time setup fee (if any) and the recurring monthly subscription fee stated in this agreement. Invoices are due within seven (7) days. Unpaid balances may result in suspension of hosting or related services after notice.
    TEXT
  end

  def default_subscription_timeline
    <<~TEXT.strip
      The partnership begins on the effective signature date and renews monthly until cancelled. Setup and launch timing follow the plan timeline communicated at kickoff.
    TEXT
  end

  def default_subscription_termination
    <<~TEXT.strip
      Either party may terminate with thirty (30) days written notice. Client remains responsible for fees accrued through the end of the notice period. Upon termination, DevDeBizz will provide a reasonable handoff of site files where applicable.
    TEXT
  end

  def default_project_scope
    <<~TEXT.strip
      DevDeBizz will design and build the website or application described in this agreement, including agreed pages/features, responsive layout, basic on-page SEO setup, and launch support. Changes outside the agreed scope require a written change order and may affect price and timeline.
    TEXT
  end

  def default_project_pricing
    <<~TEXT.strip
      Client pays the project fee stated in this agreement. Payment is due according to the invoice schedule. Work may pause if invoices remain unpaid.
    TEXT
  end

  def default_project_timeline
    <<~TEXT.strip
      Delivery follows the timeline stated in this agreement after scope is locked and required assets/content are received from the client. Delays in client feedback may extend the schedule.
    TEXT
  end

  def default_project_termination
    <<~TEXT.strip
      Either party may terminate for material breach after written notice and a reasonable cure period. Client pays for work completed through the termination date. Finished deliverables are released after outstanding invoices are paid.
    TEXT
  end
end
